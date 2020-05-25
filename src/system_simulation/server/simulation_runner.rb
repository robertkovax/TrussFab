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

# This class encapsulates the way of how system simulations (physically correct simulations of the dynamic system,
# including spring oscillations) are run. Right now we use Modelica and compile / simulate a modelica model of our
# geometry when necessary. This class provides public interfaces for different results of the simulation.
class SimulationRunner
  NODE_COORDINATES_FILTER = 'node_[0-9]+.r_0.*'.freeze
  CONSTRAINTS = %i[hitting_ground flipping min_max_compression].freeze
  NODE_RESULT_FILTER = 'node_[0-9]+\.r_0.*'.freeze
  @@status = :ready

  class SimulationError < StandardError
  end

  def self.status
    @@status
  end

  def self.new_from_json_export(json_export_string)
    @@status = :busy
    require_relative './generate_modelica_model.rb'
    modelica_model_string = ModelicaModelGenerator.generate_modelica_file(json_export_string)
    model_name = "LineForceGenerated"
    File.open(File.join(File.dirname(__FILE__), model_name + ".mo"), 'w') { |file| file.write(modelica_model_string) }

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

    # TODO: why is :spring_constants key syntax not working here?
    sim = SimulationRunner.new(model_name, spring_constants, identifiers_for_springs, mounted_users)
    @@status = :ready
    sim
  end

  def initialize(model_name = "seesaw3", spring_constants = {}, spring_identifiers = {}, mounted_users = {},
                 suppress_compilation = false, keep_temp_dir = false)

    @model_name = model_name
    @compilation_options = '-n=4 --maxMixedDeterminedIndex=100 --generateSymbolicLinearization -d=nfAPI'
    # @compilation_options += " --maxMixedDeterminedIndex=100 -n=4 --generateSymbolicLinearization"\
    #                         " --generateSymbolicJacobian"
    @simulation_options = ''
    @simulation_options += ' -lv=LOG_STATS -emit_protected -nls=kinsol -s=ida'
    # @simulation += "lv=LOG_INIT_V,LOG_SIMULATION,LOG_STATS,LOG_JAC,LOG_NLS"

    if suppress_compilation
      @directory = File.dirname(__FILE__)
    else
      @directory = Dir.mktmpdir
      puts @directory
      ObjectSpace.define_finalizer(self, proc { FileUtils.remove_entry @directory }) unless keep_temp_dir

      run_compilation
    end

    update_spring_constants(spring_constants)
    @identifiers_for_springs = spring_identifiers

    @mounted_users = mounted_users

  end

  def update_spring_constants(spring_constants)
    # maps spring edge id => spring constant
    @constants_for_springs = spring_constants
    # TODO: this just mocks the mapping between springs and the corresponding revolute joint angles. Will be changed
    # TODO: as soon as we generate the geometry dynamically.
    @angles_for_springs = { 21 => 'revRight.phi', 25 => 'revLeft.phi' }
  end

  def update_mounted_users(mounted_users)
    @mounted_users = mounted_users
  end

  def get_hub_time_series(force_vectors = [])
    data = []
    simulation_time = Benchmark.realtime { run_simulation(NODE_RESULT_FILTER, force_vectors) }
    import_time = Benchmark.realtime { data = read_csv }
    puts("simulation time: #{simulation_time}s csv parsing time: #{import_time}s")
    data
  end

  def get_spring_extensions
    run_compilation
    run_simulation("edge_from_[0-9]+_to_[0-9]+_spring.*")
    result = read_csv
    frame0 = Hash[result[0].zip(result[1].map{|val| val.to_f})]
    @identifiers_for_springs.map{|spring_id, modelica_spring|
      [spring_id, frame0["#{modelica_spring}.s_rel0"] - (frame0["#{modelica_spring}.f"] / frame0["#{modelica_spring}.c"])]
    }.to_h
  end

  def get_user_stats(node_id)
    id = "#{ModelicaModelGenerator.identifier_for_node_id(node_id)}.[r,a,v]_0"
    filter = "#{id}.*"
    run_simulation(filter)
    period_id = "#{ModelicaModelGenerator.identifier_for_node_id(node_id)}.r_0"
    velocity_id = "#{ModelicaModelGenerator.identifier_for_node_id(node_id)}.v_0"
    acceleration_id = "#{ModelicaModelGenerator.identifier_for_node_id(node_id)}.a_0"

    csv_data = read_csv_numeric
    {
      period: get_period(period_id, csv_data),
      max_acceleration: get_max_norm_and_index(acceleration_id, csv_data),
      max_velocity: get_max_norm_and_index(velocity_id, csv_data)
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

  # Returns index of animation frame when system is in equilibrium by finding the arithmetic mean of the angle
  # differences and the according index.
  def find_equilibrium(spring_id)
    run_simulation(@angles_for_springs[spring_id])
    raw_data = read_csv

    # remove initial data point, the header
    raw_data.shift
    angles = raw_data.map { |data_sample| data_sample[1].to_f }

    # center of oscillation
    equilibrium_angle = angles.min + (angles.max - angles.min) / 2
    equilibrium_data_row = raw_data.min_by do |data_row|
      # find data row with angle that is the closest to the equilibrium
      # (can't check for equality since we only have samples in time)
      (equilibrium_angle - data_row[1].to_f).abs
    end

    raw_data.index(equilibrium_data_row)
  end

  # OPTIMIZATION LOGIC

  # @param Symbol kind of constraint, one of CONSTRAINTS
  # @return Hash<String, int> new constants for spring ids
  def optimize_springs(constraint_kind)
    # TODO: remove these mocked spring and user ids
    # hash
    result_map = {}
    user_id = @mounted_users.keys[0]
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
    constant = initial_constant = 100
    id = "#{ModelicaModelGenerator.identifier_for_node_id(user_id)}.r_0"
    filter = "#{id}.*"

    step_sizes = [10_000, 1000, 200, 50]

    step_size = step_sizes.shift
    keep_searching = true
    abort_threshold = 50_000
    simulation_resolution = 0.2
    simulation_length = 4

    while keep_searching
      # puts "Current k: #{constant} Step size: #{step_size}"
      @constants_for_springs[spring_id] = constant
      run_simulation(filter, [], simulation_length, simulation_resolution)
      puts "constant #{constant}"
      if !data_valid_for_constraint(read_csv_numeric, id, constraint_kind)
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

  def get_system_matrix
    run_linearization
  end

  private

  def override_constants_string
    override_string = ''
    @identifiers_for_springs.each do |edge_id, spring_identifier|
      override_string += "#{spring_identifier}.c=#{@constants_for_springs[edge_id]},"
    end

    @mounted_users.each do |node_id, weight|
      override_string += "node_#{node_id}.m=#{weight},"
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
  def data_valid_for_constraint(csv_data, user_filter, constraint_kind)
    # TODO: for now we only optimize for not hitting the ground
    case constraint_kind
    when :hitting_ground
      vectors = csv_result_to_vectors(user_filter, csv_data)
      z_coordinates = vectors.map { |v| v[2] }
      puts "min z #{z_coordinates.min}"
      return z_coordinates.min > 0
    when :flipping
      raise NotImplementedError
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
    Open3.capture2e("cp #{@model_name}.mo  #{@directory}", chdir: File.dirname(__FILE__))
    Open3.capture2e("cp ./modelica_assets/AdaptiveSpringDamper.mo  #{@directory}", chdir: File.dirname(__FILE__))

    dependencies = ["AdaptiveSpringDamper.mo", "Modelica"]
    command = "omc #{@compilation_options} -s #{@model_name}.mo #{dependencies.join(' ')}"\
              "&& mv #{@model_name}.makefile Makefile && make -j 8"
    puts(command)
    output, status = Open3.capture2e(command,
                                chdir: @directory)
    if status.success?
      puts("Compilation Successful")
    else
      p output
      raise SimulationError, "Modelica compilation failed."
    end
  end

  def run_simulation(filter = '*', force_vectors = [], length = 10, resolution = 0.05)
    # TODO: adjust sampling rate dynamically
    overrides = "outputFormat=csv,variableFilter=#{filter},startTime=0.0,stopTime=#{length},stepSize=#{resolution}," \
                "#{force_vector_string(force_vectors)},#{override_constants_string}"
    command = "./#{@model_name} #{@simulation_options} -override=\"#{overrides}\""
    puts(command)
    Open3.popen2e(command, chdir: @directory) do |i, o, t|
      # prints out std out of the command
      o.each { |l| puts l }
      if not t.value.success?
        raise SimulationError, "Modelica simulation returned with non-zero exit code (See console output for more information)."
      end
    end
  end

  def run_linearization()
    # TODO properly parse where users sit as output
    command = "./#{@model_name} #{@simulation_options} -l=0"
    puts(command)
    Open3.popen2e(command, chdir: @directory) do |i, o, t|
      o.each { |l| puts l }
      unless t.value.success?
        raise SimulationError, "Linearization failed."
      end
      LinearStateSpaceModel.new(File.join(@directory, "linear_#{@model_name}.mo"))
    end
  end


  def read_csv
    CSV.read(File.join(@directory, "#{@model_name}_res.csv"))
  end

  def read_csv_numeric
    CSV.read(File.join(@directory, "#{@model_name}_res.csv"), headers: true, converters: :numeric)
  end

end
