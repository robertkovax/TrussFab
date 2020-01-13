#!/usr/bin/env ruby

require 'tracer'
require 'open3'

Tracer.on


#simulation_name = "TetrahedronSpring"
#mo_file = simulation_name + ".mo"
#
#puts(File.dirname(__FILE__))
#system "cd " + File.dirname(__FILE__)
#system "pwd"
#
#system "/opt/openmodelica/bin/omc -s " + mo_file + " Modelica"
#system "mv " + simulation_name + ".makefile Makefile"
#system "make"
#system "./" + simulation_name + " -override outputFormat='csv',variableFilter='pointMass.r.*',stopTime='10'"


class SimulationRunner

  def initialize
    @directory = File.dirname(__FILE__)

    Open3.popen2e("make compile", :chdir => @directory) do |i, o, t|
      o.each {|l| puts l }
      status = t.value
    end
  end

  def get_hub_time_series(hubIDs, stepSize, mass)
      overrides = "outputFormat='csv',variableFilter='node_pos.*',stopTime='20'"
      # make overrides=outputFormat='csv',variableFilter='node_pos.*',stopTime='20' simulate
      command = "make overrides=#{overrides} simulate"
      puts(command)
      Open3.popen2e(command, :chdir => @directory) do |i, o, t|
        o.each {|l| puts l }
        status = t.value
      end
  end

end

runner = SimulationRunner.new
runner.get_hub_time_series(nil, 0, 0)
