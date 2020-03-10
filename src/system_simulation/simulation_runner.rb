require 'csv'
require_relative './animation_data_sample.rb'
require 'open3'
require 'singleton'
require 'benchmark'

require 'fileutils'
require 'tmpdir'
require 'csv'

# This class encapsulates the way of how system simulations (physically correct simulations of the dynamic system,
# including spring oscillations) are run. Right now we use Modelica and compile / simulate a modelica model of our
# geometry when necessary. This class provides public interfaces for different results of the simulation.
class SimulationRunner
  NODE_COORDINATES_FILTER = 'node_[0-9]+.r_0.*'.freeze

  def self.new_from_json_export(json_export_string)
    require_relative 'generate_modelica_model.rb'
    modelica_model_string = generate_modelica_file(json_export_string)
    model_name = "LineForceGenerated"
    File.open(File.join(File.dirname(__FILE__), model_name + ".mo"), 'w') { |file| file.write(modelica_model_string) }

    graph = JSON.parse(json_export_string)

    # build modelica model identifiers for each spring from their ids
    identifiers_for_springs = graph['spring_constants'].map do |edge_id, constant|
      edges = graph['edges'].map { |edge| [edge['id'].to_s, edge] }.to_h
      edge_with_spring = edges[edge_id]
      [edge_id, "edge_from_#{edge_with_spring['n1']}_to_#{edge_with_spring['n2']}_spring"]
    end.to_h

    # TODO: why is :spring_constants key syntax not working here?
    SimulationRunner.new(model_name, graph['spring_constants'], identifiers_for_springs)
  end

  def initialize(model_name = "seesaw3", spring_constants = {}, spring_identifiers = {}, suppress_compilation = false, keep_temp_dir = false)
    @model_name = model_name
    @simulation_options = "-abortSlowSimulation"
    # @simulation += "lv=LOG_INIT_V,LOG_SIMULATION,LOG_STATS,LOG_JAC,LOG_NLS"
    @compilation_options = "--maxSizeLinearTearing=300 --maxMixedDeterminedIndex=100 -n=4"

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

  end

  def update_spring_constants(spring_constants)
    # maps spring edge id => spring constant
    @constants_for_springs = spring_constants
    # TODO: this just mocks the mapping between springs and the corresponding revolute joint angles. Will be changed
    # TODO: as soon as we generate the geometry dynamically.
    @angles_for_springs = { 21 => 'revRight.phi', 25 => 'revLeft.phi' }
  end


  def get_hub_time_series
    data = []
    simulation_time = Benchmark.realtime { run_simulation(NODE_COORDINATES_FILTER) }
    import_time = Benchmark.realtime { data = read_csv }
    puts("simulation time: #{simulation_time}s csv parsing time: #{import_time}s")
    data
  end

  def get_period(mass = 20, constant = 5000)
    # TODO: confirm correct result
    run_simulation

    require 'gsl'

    stop_time = 10

    # TODO: make this call use read_csv
    data = CSV.read(File.join(@directory, "#{@model_name}_res.csv"), headers: true)['revLeft.phi']
    vector = data.map(&:to_f).to_gv

    sample_rate = vector.length / stop_time

    # https://github.com/SciRuby/rb-gsl/blob/master/examples/fft/fft.rb
    y2 = vector.fft.subvector(1, data.length - 2).to_complex2
    mag = y2.abs
    f = GSL::Vector.linspace(0, sample_rate/2, mag.size)
    #p mag.max_index
    1 / f[mag.max_index]
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

  # This function approximates a optimum (= the biggest spring constant that makes the spring still stay in the angle
  # constrains) by starting with a very low spring constant (which leads to a very high oscillation => high angle delta)
  # and approaches the optimum by approaching with different step sizes (= resolutions of the search), decreasing the
  # step size as soon as the spring constant is not valid anymore and thus approximating the highest valid spring
  # constant.
  def constant_for_constrained_angle(allowed_angle_delta = Math::PI / 2.0, spring_id = 25, initial_constant = 500)
    # steps which the algorithm uses to approximate the valid spring constant

    angle_filter = @angles_for_springs[spring_id]
    step_sizes = [1500, 1000, 200, 50, 5]
    constant = initial_constant
    step_size = step_sizes.shift
    keep_searching = true
    abort_threshold = 50_000
    while keep_searching
      # puts "Current k: #{constant} Step size: #{step_size}"
      @constants_for_springs[spring_id] = constant
      run_simulation(angle_filter)
      if !angle_valid(read_csv, allowed_angle_delta)
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

    constant
  end

  private

  def override_constants_string
    override_string = ''
    @identifiers_for_springs.each do |edge_id, spring_identifier|
      override_string += "#{spring_identifier}.c='#{@constants_for_springs[edge_id]}',"
    end

    # remove last comma
    override_string[0...-1]
  end

  def angle_valid(data, max_allowed_delta = Math::PI / 2.0)
    data = data.map { |data_sample| data_sample[1].to_f }
    # remove initial data point since it's only containing the column header
    data.shift

    delta = data.max - data.min
    puts "delta: #{delta} maxdelta: #{max_allowed_delta} max: #{data.max}, min: #{data.min}, "
    delta < max_allowed_delta
  end

  def run_compilation
    output, _ = Open3.capture2e("cp #{@model_name}.mo  #{@directory}", chdir: File.dirname(__FILE__))
    p output
    output, _ = Open3.capture2e("omc #{@compilation_options} -s #{@model_name}.mo Modelica && mv #{@model_name}.makefile Makefile && make -j 8",
                                chdir: @directory)
    p output
  end

  def run_simulation(filter = '*')
    # TODO adjust sampling rate dynamically
    overrides = "outputFormat='csv',variableFilter='#{filter}',startTime=0.3,stopTime=10,stepSize=0.1,#{override_constants_string}"
    command = "./#{@model_name} -override #{overrides}"
    puts(command)
    Open3.popen2e(command, chdir: @directory) do |i, o, t|
      # prints out std out of the command
      o.each { |l| puts l }
    end
  end

  def read_csv
    CSV.read(File.join(@directory, "#{@model_name}_res.csv"))
  end

end

