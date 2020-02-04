#!/usr/bin/env ruby

require 'csv'
require_relative './animation_data_sample.rb'
require 'open3'

RUBY_EXECUTABLE_WITH_GSL = 'ruby'

class SimulationRunner

  def initialize
    @directory = File.dirname(__FILE__)

    Open3.popen2e("make compile", :chdir => @directory) do |i, o, t|
      o.each {|l| puts l }
      status = t.value
    end
  end

  def get_hub_time_series(hubIDs, stepSize, mass, constant=50)
    data = []
    simulation_time = Benchmark.realtime { run_simulation(constant, "node_pos.*") }
    import_time = Benchmark.realtime { data = import_csv(File.join(File.dirname(__FILE__), "seesaw3_res.csv")) }
    puts("simulation time: #{simulation_time.to_s}s csv parsing time: #{import_time.to_s}s")
    data
  end

  def get_period(constant=5)
    run_simulation(constant, "revLeft.phi")
    # Since Sketchup makes Installation of Gems really hard, we have to run the script in an ruby environement somewhere outside
    output, signal = Open3.capture2e("#{RUBY_EXECUTABLE_WITH_GSL} -r #{__FILE__} -e \"p SimulationRunner.get_period_from_file\"", :chdir => @directory)
    return output.split("\n")[0].to_f
  end


  def self.get_period_from_file()
    require 'gsl'
    require 'csv'

    sampling_rate = 10

    data = CSV.read((File.join(File.dirname(__FILE__), "seesaw3_res.csv")), :headers=>true)['revLeft.phi']

    vector = data.map{ |v| v.to_f }.to_gv

    # https://github.com/SciRuby/rb-gsl/blob/master/examples/fft/fft.rb
    y2 = vector.fft.subvector(1, data.length - 2).to_complex2
    mag = y2.abs
    f = GSL::Vector.linspace(0, sampling_rate/2, mag.size)
    # p mag.to_a
    # p f.to_a
    return 1 / f[mag.max_index]
  end


  private

  def run_simulation(constant, filter="*")
    # TODO adjust sampling rate dynamically
    overrides = "outputFormat='csv',variableFilter='#{filter}',startTime=0,stopTime=10,stepSize=0.2,springDamperParallel1.c='#{constant}'"
    # make overrides=outputFormat='csv',variableFilter='node_pos.*',stopTime='20' simulate
    command = "make overrides=#{overrides} simulate"
    puts(command)
    Open3.popen2e(command, :chdir => @directory) do |i, o, t|
      o.each {|l| puts l }
      status = t.value
    end
  end

  def import_csv(file)
    raw_data = CSV.read(file)

    # parse in which columns the coordinates for each node are stored
    indices_map = AnimationDataSample.indices_map_from_header(raw_data[0])

    #remove header of loaded data
    raw_data.shift()

    # parse csv
    data_samples = []
    raw_data.each do | value |
      data_samples << AnimationDataSample.from_raw_data(value, indices_map)
    end

    # todo DEBUG
    #data_samples.each {|sample| puts sample.inspect}

    data_samples

  end

end

# runner = SimulationRunner.new
# p 'yo'
# p runner.get_period(70,60)
