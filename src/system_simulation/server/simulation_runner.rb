require 'csv'
require 'open3'
require 'singleton'
require 'benchmark'
require 'fileutils'
require 'tmpdir'
require 'csv'
require 'matrix'

require_relative '../animation_data_sample.rb'
require_relative './generate_modelica_model.rb'
require_relative './linear_state_space_model.rb'

# This class encapsulates the way of how system simulations (physically correct simulations of the dynamic system,
# including spring oscillations) are run. Right now we use Modelica and compile / simulate a modelica model of our
# geometry when necessary. This class provides public interfaces for different results of the simulation.
class SimulationRunner
  NODE_COORDINATES_FILTER = 'node_[0-9]+.r_0.*'.freeze
  CONSTRAINTS = %i[hitting_ground flipping min_max_compression].freeze
  NODE_RESULT_FILTER = 'node_[0-9]+\.r_0.*'.freeze
  OPTIMIZE_MIN_SPRING_LENGTH = 0.3
  OPTIMIZE_MAX_SPRING_LENGTH = 0.7
  SOFT_SPRING_CONSTANT = 100
  STIFF_SPRING_CONSTANT = 25000

  class SimulationError < StandardError
  end

  def self.new_from_json_export(json_export_string)
    require_relative './generate_modelica_model.rb'
    modelica_model_string = ModelicaModelGenerator.generate_modelica_file(json_export_string)
    model_name = 'LineForceGenerated'
    File.open(File.join(File.dirname(__FILE__), model_name + '.mo'), 'w') { |file| file.write(modelica_model_string) }

    trussfab_geometry = JSON.parse(json_export_string)

    spring_constants = {}
    identifiers_for_springs = {}
    mounted_users = {}

    if trussfab_geometry['spring_constants']
      # build modelica model identifiers for each spring from their ids
      identifiers_for_springs = trussfab_geometry['spring_constants'].map do |edge_id, constant|
        edges = trussfab_geometry['edges'].map { |edge| [edge['id'].to_s, edge] }.to_h
        edge_with_spring = edges[edge_id]
        [edge_id, "edge_from_#{edge_with_spring['n1']}_to_#{edge_with_spring['n2']}_spring"]
      end.to_h
    end
    spring_constants = trussfab_geometry['spring_constants'] if trussfab_geometry['spring_constants']
    mounted_users = trussfab_geometry['mounted_users'] if trussfab_geometry['mounted_users']

    @preloaded_energy_level = 0

    # TODO: why is :spring_constants key syntax not working here?
    SimulationRunner.new(model_name, spring_constants, identifiers_for_springs, mounted_users, trussfab_geometry)
  end

  def initialize(model_name = 'seesaw3', spring_constants = {}, spring_identifiers = {}, mounted_users = {},
                 suppress_compilation = false, keep_temp_dir = false, original_json)

    @model_name = model_name
    @original_json = original_json
    @compilation_options = '--maxMixedDeterminedIndex=100'
    @simulation_options = '-lv=LOG_STATS,LOG_EVENTS -emit_protected -s=ida -ls=umfpack'

    if suppress_compilation
      @directory = File.dirname(__FILE__)
    else
      @directory = Dir.mktmpdir
      puts @directory
      ObjectSpace.define_finalizer(self, proc { FileUtils.remove_entry @directory }) unless keep_temp_dir

      run_compilation
    end

    @identifiers_for_springs = spring_identifiers
    @user_excitement = {}
    update_spring_constants(spring_constants)
    update_mounted_users(mounted_users)
  end

  def update_spring_constants(spring_constants)
    # maps spring edge id => spring constant
    @constants_for_springs = spring_constants
  end

  def update_mounted_users(mounted_users)
    @mounted_users = mounted_users
    @mounted_users.keys.each{|user_id| @user_excitement[user_id] = 50}
  end

  def update_mounted_users_excitement(user_excitement)
    @user_excitement = user_excitement
  end

  def update_preloaded_energy_level(prelaod_energy)
    @preloaded_energy_level = prelaod_energy
    p prelaod_energy
  end

  def get_hub_time_series(force_vectors = [])
    data = []
    simulation_time = Benchmark.realtime { run_simulation(NODE_RESULT_FILTER, force_vectors) }
    import_time = Benchmark.realtime { data = read_csv }
    puts("simulation time: #{simulation_time}s csv parsing time: #{import_time}s")
    data
  end

  def get_spring_extensions
    # start at 0.1s to relax the initial forces
    run_simulation('edge_from_[0-9]+_to_[0-9]+_spring.*', [], 1, 0.1, 0.1)
    result = read_csv
    frame0 = result[0].zip(result[1].map{|val| val.to_f}).to_h

    @identifiers_for_springs.map{|spring_id, modelica_spring|
      # [spring_id, @original_json["edges"].find{|edge| spring_id == edge["id"].to_s}["uncompressed_length"] / 1000 - (frame0["#{modelica_spring}.f"] / @constants_for_springs[spring_id])]
      p frame0["#{modelica_spring}.f"]
      [spring_id, frame0["#{modelica_spring}.s_rel"] - (frame0["#{modelica_spring}.f_c"] / @constants_for_springs[spring_id])]
    }.to_h
  end

  def get_user_stats(node_id)
    id = "#{ModelicaModelGenerator.identifier_for_node_id(node_id)}.[r,a,v]_0"
    filter = "#{id}.*"
    run_simulation(filter)
    period_id = "#{ModelicaModelGenerator.identifier_for_node_id(node_id)}.r_0"
    # get_preload_release_time_series(100, filter)
    run_simulation(filter)
    # period_id = "#{ModelicaModelGenerator.identifier_for_node_id(node_id)}.r_0"
    velocity_id = "#{ModelicaModelGenerator.identifier_for_node_id(node_id)}.v_0"
    acceleration_id = "#{ModelicaModelGenerator.identifier_for_node_id(node_id)}.a_0"
    csv_data = read_csv_numeric
    csv_data.each{|row| p row}
    {
      period: 10,
      max_acceleration: get_max_norm_and_index(acceleration_id, csv_data),
      max_velocity: get_max_norm_and_index(velocity_id, csv_data),
      time_velocity: get_time_series(velocity_id, csv_data),
      time_acceleration: get_time_series(acceleration_id, csv_data)
    }
  end

  def get_max_norm_and_index(id, csv_data)
    max_norm = 0
    max_index = 0
    csv_data["#{id}[1]"].each_with_index do |value, index|
      norm = Vector.elements([value.to_f, csv_data["#{id}[2]"][index].to_f, csv_data["#{id}[3]"][index].to_f]).norm
      if norm > max_norm
        max_norm = norm
        max_index = index
      end
    end
    { value: max_norm, index: max_index }
  end

  def get_time_series(id, csv_data)
    csv_data.map do |x| { 'time' => x['time'], "x" => x["#{id}[1]"], "y" => x["#{id}[2]"], "z" => x["#{id}[3]"]}
    end
  end

  def get_period(id, csv_data)
    require 'gsl'

    time_steps = csv_data.length
    time_step_size = csv_data['time'][1] - csv_data['time'][0]
    sample_rate = time_step_size * time_steps

    # https://github.com/SciRuby/rb-gsl/blob/master/examples/fft/fft.rb
    x = csv_data["#{id}[1]"].to_gv.fft.subvector(1, time_steps - 2).to_complex2
    y = csv_data["#{id}[2]"].to_gv.fft.subvector(1, time_steps - 2).to_complex2
    z = csv_data["#{id}[3]"].to_gv.fft.subvector(1, time_steps - 2).to_complex2

    mag = x.abs + y.abs + z.abs
    f = GSL::Vector.linspace(0, sample_rate, mag.size)

    # p f.to_a
    # p mag.to_a
    # GSL::graph(f, mag, "-C -g 3 -x 0 200 -X 'Frequency [Hz]'")

    frequency = f[mag.max_index]

    frequency != 0 ? 1 / frequency : nil
  end

  def get_damping_characteristic
    require "gsl"

    # run the force sweep
    filters = ["edge_from_[0-9]+_to_[0-9]+_spring.*", ".*\\.energy"]
    # overrides = @identifiers_for_springs.select{|id, _| enabled_springs.include?(id)}.map{|id, modelica_id| "#{modelica_id.sub("_spring", "")}_force_ramp.height=3000"}.join(",")
    run_simulation(filters.join("|"), [], 10, 0.05, 0)
    result = read_csv_numeric.map do |row|
      row_h = row.to_h
      overall_loss_power = 0
      row_h.map{|key, value|
        if key.include?("energy")
          overall_loss_power += value
        end
      }
      overall_loss_power
    end
    time = read_csv_numeric.map{|row| row["time"]}

    p result
    min_val = result.min
    result = result.map { |e| e -  min_val + 0.001 }

    # Fitting
    time_vector = time.drop(1).to_gv
    result_vector = result.drop(1).map{|i| Math.log(i)}.to_gv

    a2, b2, = GSL::Fit.linear(time_vector, result_vector)
    a = Math.exp(a2)
    p a, b2
    c = min_val

    p time.map{|x| a * Math::E**(b2 * x) + c}
  end

  def get_preload_release_time_series(prelaod_energy=@prelaod_energy, filter="")
    max_energy_ramp_per_spring = 2000

    enabled_springs = @identifiers_for_springs.keys.map{|elem| elem.to_i }

    preloaded_springs = @identifiers_for_springs.select{|id, _| enabled_springs.include?(id.to_i)}
    p @identifiers_for_springs
    if preloaded_springs.empty?
      raise "no valid spring was selected; aborting preloading"
    end

    filters = [NODE_RESULT_FILTER, "systemEnergy", "released", "startEnergy", "nettoSystemEnergy", filter]
    overrides = preloaded_springs.map{|id, modelica_id| "#{modelica_id.sub("_spring", "")}_force_ramp.height=#{max_energy_ramp_per_spring}"}
    overrides += ["releaseEnergy=#{prelaod_energy}"]

    data = []
    simulation_time = Benchmark.realtime { run_simulation(filters.join("|"), [], 100, 0.5, 100, overrides.join(",")) }
    import_time = Benchmark.realtime { data = read_csv }
    puts("simulation time: #{simulation_time}s csv parsing time: #{import_time}s")
    # p data.map{ |row| row[data[0].find_index("released")]}.drop(1)
    # p data.map{ |row| row[data[0].find_index("released")]}.drop(1)
    # p data.map{ |row| row[data[0].find_index("nettoSystemEnergy")]}.drop(1)

    data = [data[0]].push(*data.select{|row| row[data[0].find_index("released")] == "1" })
    data
  end

  def get_preloaded_positions(prelaod_energy=100, enabled_springs=[])
    enabled_springs = enabled_springs.map{|elem| elem.to_i }
    p "starting preloading of #{prelaod_energy}J for springs: #{enabled_springs.join(", ")}."
    time_far_far_away = 100
    long_time_for_ramping_up = 100

    def get_node_id_from_modelica_component_name(modelica_component_name)
      modelica_component_name.match(/(?<=node_)\d+/)
    end

    def percentage(n)
      (n * 100).round(1).to_s + "%"
    end

    preloaded_springs = @identifiers_for_springs.select{|id, _| enabled_springs.include?(id.to_i)}
    if preloaded_springs.empty?
      raise "no valid spring was selected; aborting preloading"
    end

    # run the force sweep
    filters = [".*\\.energy", "node_[0-9]+\\.r_0.*", "edge_from_[0-9]+_to_[0-9]+_spring.s_rel", "edge_from_[0-9]+_to_[0-9]+\\.r_CM_0.*"]
    overrides = preloaded_springs.map{|id, modelica_id| "#{modelica_id.sub("_spring", "")}_force_ramp.height=1000"}.join(",")
    run_simulation(filters.join("|"), [], long_time_for_ramping_up, 1, time_far_far_away, overrides)
    result_energy = read_csv_numeric.map do |row|
      row_h = row.to_h
      overall_loss_power = 0
      row_h.map{|key, value|
        if key.include?("energy")
          overall_loss_power += value
        end
      }
      overall_loss_power
    end

    # return positions where the energy matches most closley
    # we are taking a value from the beginning, but no from the very beginning to avoid turbulences caused by the first hit of force
    initial_potential_energy = result_energy[2]

    destination_energy = result_energy.map{|val| (val - prelaod_energy - initial_potential_energy).abs}
    energy_error = (destination_energy.min).abs / (prelaod_energy)
    p "For the target energy #{prelaod_energy}J the energy fo +/- #{destination_energy.min} can be achieved. That is an error of #{percentage(energy_error)}."
    p "The preloading curves looks like this:"
    p result_energy
    p destination_energy

    if energy_error > 0.3
      raise "we couldn't preload the model with #{prelaod_energy}J. The the best guess was off by #{percentage(energy_error)}."
    end

    data_w_header = read_csv
    return_array = []
    return_array << data_w_header[0]
    return_array << data_w_header[destination_energy.rindex(destination_energy.min) + 1]
  end

  def get_steady_state_positions()
    time_when_probably_nothing_happens_anymore = 1000
    filters = ["node_[0-9]+\\.r_0.*"]
    run_simulation(filters.join("|"), [],  1, 1, time_when_probably_nothing_happens_anymore)
    read_csv[0]
  end


  def linearize
    run_linearization
  end

  # OPTIMIZATION LOGIC

  # @param Symbol kind of constraint, one of CONSTRAINTS
  # @return Hash<String, int> new constants for spring ids
  def optimize_springs(constraint_kind)
    # TODO: remove these mocked spring and user ids
    # hash
    result_map = {}
    user_id = @mounted_users.keys[0]

    # First, set every spring's constant to a very stiff value
    @constants_for_springs.each do |spring_id, _constant|
      @constants_for_springs[spring_id] = STIFF_SPRING_CONSTANT
    end

    # Then try to optimize each spring individually by starting with a very low spring constant (= soft)
    @constants_for_springs.each do |spring_id, _constant|
      result_map[spring_id] = optimize_spring_for_constraint(spring_id, user_id, constraint_kind)
    end
    result_map
  end

  # This function approximates a optimum (= the biggest spring constant that makes the spring still stay in the specific
  # constrain) by starting with a very low spring constant (which leads to a very high oscillation => high amplitude)
  # and approaches the optimum by approaching with different step sizes (= resolutions of the search), decreasing the
  # step size as soon as the spring constant is not valid anymore and thus approximating the highest valid spring
  # constant.
  # @param [Symbol] constraint_kind specifying the kind of constrain
  # @param [String] spring_id
  def optimize_spring_for_constraint(spring_id, user_id, constraint_kind)
    # TODO: probably we want to specify into which direction we want to go (in our search),
    # TODO: right now we decrease the constant

    # constant = initial_constant = @constants_for_springs[spring_id]
    constant = initial_constant = SOFT_SPRING_CONSTANT
    user_modelica_string = "#{ModelicaModelGenerator.identifier_for_node_id(user_id)}.r_0"
    user_filter = "#{user_modelica_string}.*"

    spring_modelica_string = "#{@identifiers_for_springs[spring_id.to_s]}.s_rel"
    spring_filter = "#{spring_modelica_string}.*"

    step_sizes = [10_000, 1000, 200, 50]

    step_size = step_sizes.shift
    keep_searching = true
    abort_threshold = 50_000
    simulation_resolution = 0.05
    simulation_length = 4

    while keep_searching
      # puts "Current k: #{constant} Step size: #{step_size}"
      @constants_for_springs[spring_id] = constant
      run_simulation("#{user_filter}|#{spring_filter}", [], simulation_length, simulation_resolution)
      puts "constant #{constant}"
      if !data_valid_for_constraint(read_csv_numeric, user_modelica_string, spring_modelica_string, constraint_kind)
        # increase spring constant to decrease angle delta
        constant += step_size
      elsif !step_sizes.empty?
        # go back last step_size
        constant -= step_size
        # reduce step size and continue
        step_size = step_sizes.shift
        # make sure we don't exceed the sample space
        constant = initial_constant if constant < initial_constant
      else
        # we reached smallest step size and found a valid spring constant, so we're done
        keep_searching = false
      end

      keep_searching = false if constant >= abort_threshold
    end

    puts "Optimized spring ##{spring_id} – constant: #{constant}N/m"
    @constants_for_springs[spring_id] = constant
    constant

    # TODO: use spring catalog / picking logic from spring_picker.rb to pick the fitting spring (get_spring)
    # TODO: right now we're just setting the constant to the exact value (without checking if there really is a spring
    # TODO: with that constant)
  end



  private

  def override_constants_string
    override_string = ''
    @identifiers_for_springs.each do |edge_id, spring_identifier|
      override_string += "#{spring_identifier}.c=#{@constants_for_springs[edge_id]},"
    end

    # Increase Damping for everthing that is not a spring
    @original_json["edges"].select{ |edge| @constants_for_springs[edge["id"].to_s] === nil}.each do |edge|
      override_string += "edge_from_#{edge["n1"]}_to_#{edge["n2"]}_spring.d=10000,"
    end

    @mounted_users.each do |node_id, weight|
      override_string += "node_#{node_id}.m=#{weight},"
    end

    @user_excitement.each do |node_id, excitement|
      override_string += "node_#{node_id}.excitement=#{excitement},"
    end

    # remove last comma
    override_string[0...-1] if override_string.length != 0
  end

  def force_vector_string(force_vectors)
    force_vectors_string = ''
    force_vectors.each do |force_vector|
      override_string = "node_#{force_vector['node_id']}_force_val[1]=#{force_vector['x']}," \
                        "node_#{force_vector['node_id']}_force_val[2]=#{force_vector['y']}," \
                        "node_#{force_vector['node_id']}_force_val[3]=#{force_vector['z']}"
      force_vectors_string += override_string
      force_vectors_string += ','
    end
    force_vectors_string[0...-1] if force_vectors_string.length != 0
  end

  # @param [Symbol] constraint_kind specifying the kind of constrain
  # @param [Array<Array<String>>] csv_data
  def data_valid_for_constraint(csv_data, user_filter, spring_filter, constraint_kind)
    # TODO: for now we only optimize for not hitting the ground
    case constraint_kind
    when :hitting_ground
      vectors = csv_result_to_vectors(user_filter, csv_data)
      z_coordinates = vectors.map { |v| v[2] }
      puts "min z #{z_coordinates.min}"
      return z_coordinates.min > 0
    when :flipping
      min_length = csv_data[spring_filter].map{ |spring_length| spring_length.to_f}.min
      max_length = csv_data[spring_filter].map{ |spring_length| spring_length.to_f}.max
      return min_length > OPTIMIZE_MIN_SPRING_LENGTH && max_length < OPTIMIZE_MAX_SPRING_LENGTH
    when :min_max_compression
      raise NotImplementedError
    end
    false
  end

  # @param [String] key
  # @param [Array] csv_data
  # @return [Array<Vector>] vectors
  def csv_result_to_vectors(key, csv_data)
    vectors = []
    csv_data["#{key}[1]"].each_with_index do |value, index|
      vector = Vector.elements([value.to_f, csv_data["#{key}[2]"][index].to_f, csv_data["#{key}[3]"][index].to_f])
      vectors << vector
    end
    vectors
  end

  def run_compilation
    Open3.capture2e("cp *.mo  #{@directory} && cp ./modelica_assets/*.mo", chdir: File.dirname(__FILE__))

    dependencies = ['Spring.mo', 'PointMass.mo', 'LineForce.mo', 'Fixture.mo', 'Modelica']

    # copy custom modelica files
    dependencies.select{ |item| item.end_with?(".mo") }.each do |file_name|
     Open3.capture2e("cp ./modelica_assets/#{file_name}  #{@directory}", chdir: File.dirname(__FILE__))
   end

    command = "omc #{@compilation_options} -s #{@model_name}.mo #{dependencies.join(' ')} "\
              "&& mv #{@model_name}.makefile Makefile && make -j 16"
    puts(command)
    output, status = Open3.capture2e(command,
                                chdir: @directory)
    if status.success?
      puts('Compilation Successful')
    else
      puts(output)
      raise SimulationError, 'Modelica compilation failed.'
    end
  end

  def run_simulation(filter = '*', force_vectors = [], length = 5, resolution = 0.033, start=0.01, additional_overrides = "")
    # TODO: adjust sampling rate dynamically
    overrides = "outputFormat=csv,tolerance=1e-3,variableFilter=#{filter},startTime=#{start},stopTime=#{start + length},stepSize=#{resolution}," \
                "#{force_vector_string(force_vectors)},#{override_constants_string},#{additional_overrides}"

    command = "./#{@model_name} #{@simulation_options} -override=\"#{overrides}\""
    puts(command)
    Open3.popen2e(command, chdir: @directory) do |i, o, t|
      # prints out std out of the command
      o.each { |l| puts l }
      if not t.value.success?
        raise SimulationError, 'Modelica simulation returned with non-zero exit code (See console output for more information).'
      end
    end
  end

  def run_linearization()
    # TODO properly parse where users sit as output
    command = "./#{@model_name}  -lv=LOG_STATS  -override=\"#{override_constants_string}\" -l=0"
    puts(command)
    linear_model = nil
    Open3.popen2e(command, chdir: @directory) do |i, o, t|
      o.each { |l| puts l }
      unless t.value.success?
        raise SimulationError, 'Linearization failed.'
      end
      linear_model = LinearStateSpaceModel.new(File.join(@directory, "linear_#{@model_name}.mo"))
    end
    linear_model
  end


  def read_csv
    CSV.read(File.join(@directory, "#{@model_name}_res.csv"))
  end

  def read_csv_numeric
    CSV.read(File.join(@directory, "#{@model_name}_res.csv"), headers: true, converters: :numeric)
  end

end
