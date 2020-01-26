#!/usr/bin/env ruby

require 'csv'
require_relative './animation_data_sample.rb'
require 'open3'

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

  def get_period(mass=70, constant=50)
    run_simulation("revLeft.phi")
    @data = import_csv(File.join(File.dirname(__FILE__), "seesaw3_res.csv"))
    print @data
    my_array = [[1,2,3.5,4],[3,5.2,7,22]]
    #my_fft = my_array.fft
    #print my_fft
  end


  private

  def run_simulation(constant, filter="*")
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

 #runner = SimulationRunner.new
 #runner.get_period(70,60)
