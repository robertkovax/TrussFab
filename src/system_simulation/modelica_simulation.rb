require 'open3'

class ModelicaSimulation

  def self.run_simulation(simulation_name="seesaw3")

    result_file = simulation_name + "_res.csv"

    puts 'Searching in:'
    directory = File.dirname(__FILE__)
    puts directory

    Open3.popen2e("rm #{result_file}", :chdir => directory) do |i, o, t|
      o.each {|l| puts l }
      status = t.value
      # p o.gets
    end

    Open3.popen2e("make", :chdir => directory) do |i, o, t|
      o.each {|l| puts l }
      status = t.value
      # p o.gets
    end
    # system
    # puts("Compiling into executable")
    # system "make"
    # puts("Executing Simulation")
    # puts(system "./" + simulation_name + " -override outputFormat='csv',variableFilter='pointMass.r.*',stopTime='5'")
  end

end
