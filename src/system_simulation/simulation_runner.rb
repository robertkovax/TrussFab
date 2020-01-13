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
      overrides = "outputFormat='csv',variableFilter='node_pos.*',startTime=0,stopTime=10,stepSize=0.2,springDamperParallel1.c='#{constant}'"
      # make overrides=outputFormat='csv',variableFilter='node_pos.*',stopTime='20' simulate
      command = "make overrides=#{overrides} simulate"
      puts(command)
      Open3.popen2e(command, :chdir => @directory) do |i, o, t|
        o.each {|l| puts l }
        status = t.value
      end
  end

end

#runner = SimulationRunner.new
#runner.get_hub_time_series(nil, 0, 0)
