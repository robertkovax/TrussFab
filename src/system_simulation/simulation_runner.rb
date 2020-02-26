require 'csv'
require_relative './animation_data_sample.rb'
require 'open3'
require 'singleton'
require 'benchmark'

require 'fileutils'
require 'tmpdir'

# This class encapsulates the way of how system simulations (physically correct simulations of the dynamic system,
# including spring oscillations) are run. Right now we use Modelica and compile / simulate a modelica model of our
# geometry when necessary. This class provides public interfaces for different results of the simulation.
class SimulationRunner
  include Singleton

  def initialize(suppress_compilation = false, keep_temp_dir = false)
    @model_name = 'seesaw3'

    if suppress_compilation
      @directory = File.dirname(__FILE__)
    else
      @directory = Dir.mktmpdir
      puts @directory
      ObjectSpace.define_finalizer(self, proc { FileUtils.remove_entry @directory }) unless keep_temp_dir

      run_compilation
    end
  end

  def get_hub_time_series(hub_ids, step_size, mass, constant = 50)
    data = []
    simulation_time = Benchmark.realtime { run_simulation(constant, mass, 'node_pos.*') }
    import_time = Benchmark.realtime { data = parse_data(read_csv) }
    puts("simulation time: #{simulation_time}s csv parsing time: #{import_time}s")
    data
  end

  def get_period(mass = 20, constant = 5000)
    # TODO: confirm correct result
    run_simulation(constant, mass, 'revLeft.phi')

    require 'gsl'
    require 'csv'

    stop_time = 10

    # TODO: make this call use read_csv
    data = CSV.read(File.join(@directory, "#{@model_name}_res.csv"), headers: true)['revLeft.phi']
    vector = data.map(&:to_f).to_gv

    sample_rate = vector.length / stop_time

    # https://github.com/SciRuby/rb-gsl/blob/master/examples/fft/fft.rb
    y2 = vector.fft.subvector(1, data.length - 2).to_complex2
    mag = y2.abs
    f = GSL::Vector.linspace(0, sample_rate / 2, mag.size)

    1 / f[mag.max_index]
  end

  # Returns index of animation frame when system is in equilibrium by finding the arithmetic mean of the angle
  # differences and the according index.
  def find_equilibrium(constant = 50, mass = 20)
    run_simulation(constant, mass, 'revLeft.phi')
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

  def constant_for_constrained_angle(allowed_angle_delta = Math::PI / 2.0, initial_constant = 500, mass = 20,
                                     spring_id = 0, angle_id = 0)
    # steps which the algorithm uses to approximate the valid spring constant
    step_sizes = [1500, 1000, 200, 50, 5]
    constant = initial_constant
    step_size = step_sizes.shift
    keep_searching = true
    abort_threshold = 50_000
    while keep_searching
      # puts "Current k: #{constant} Step size: #{step_size}"
      run_simulation(constant, mass, 'revLeft.phi')
      if !angle_valid(read_csv, allowed_angle_delta)
        # increase spring constant to decrease angle delta
        constant += step_size
      elsif !step_sizes.empty?
        # go back last step_size
        constant -= step_size
        # reduce step size and continue
        step_size = step_sizes.shift
      else
        # we reached smallest step size and found a valid spring constant, so we're done
        keep_searching = false
      end

      keep_searching = false if constant >= abort_threshold
    end

    constant
  end

  private

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
    output, _ = Open3.capture2e("omc -s #{@model_name}.mo && mv #{@model_name}.makefile Makefile && make -j 8",
                                chdir: @directory)
    p output
  end

  def run_simulation(constant, mass, filter = '*')
    # TODO adjust sampling rate dynamically
    overrides = "outputFormat='csv',variableFilter='#{filter}',startTime=0.3,stopTime=10,stepSize=0.1,springDamperParallel1.c='#{constant}'"
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

  def parse_data(raw_data)
    # parse in which columns the coordinates for each node are stored
    indices_map = AnimationDataSample.indices_map_from_header(raw_data[0])

    # remove header of loaded data
    raw_data.shift

    # parse csv
    data_samples = []
    raw_data.each do |value|
      data_samples << AnimationDataSample.from_raw_data(value, indices_map)
    end

    data_samples

  end

end

