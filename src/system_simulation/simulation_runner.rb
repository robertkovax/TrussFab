#!/usr/bin/env ruby

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
    _run_simulation(constant, "node_pos.*")
  end

  def _run_simulation(constant, filter="*")
    overrides = "outputFormat='csv',variableFilter='#{filter}',startTime=0,stopTime=10,stepSize=0.2,springDamperParallel1.c='#{constant}'"
    # make overrides=outputFormat='csv',variableFilter='node_pos.*',stopTime='20' simulate
    command = "make overrides=#{overrides} simulate"
    puts(command)
    Open3.popen2e(command, :chdir => @directory) do |i, o, t|
      o.each {|l| puts l }
      status = t.value
    end
  end

  def get_period(mass=70, constant=50)
    _run_simulation("revLeft.phi")
    @data = ModellicaExport.import_csv("seesaw3_res.csv")
    print @data
    my_array = [[1,2,3.5,4],[3,5.2,7,22]]
    my_fft = my_array.fft
    print my_fft
  end

end

# runner = SimulationRunner.new
# runner.get_period(70,60)
