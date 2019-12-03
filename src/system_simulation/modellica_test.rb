#!/usr/bin/env ruby

require 'tracer'

Tracer.on

simulation_name = "TetrahedronSpring"
mo_file = simulation_name + ".mo"

puts(File.dirname(__FILE__))
system "cd " + File.dirname(__FILE__)
system "pwd"

system "/opt/openmodelica/bin/omc -s " + mo_file + " Modelica"
system "mv " + simulation_name + ".makefile Makefile"
system "make"
system "./" + simulation_name + " -override outputFormat='csv',variableFilter='pointMass.r.*',stopTime='10'"

# File.open(simulation_name + "_res.csv", "r") do |f|
#   f.each_line do |line|
#     puts line
#   end
# end




# File.open(mo_file, "r") do |f|
#   f.each_line do |line|
#     puts line
#   end
# end
