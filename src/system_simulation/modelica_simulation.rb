require 'open3'

class ModelicaSimulation

  def self.run_simulation(simulation_name="TetrahedronSpring")

    mo_file = simulation_name + ".mo"

    puts("Compiling into flattened modelica model")

    directory = File.dirname(__FILE__)

    path = File.join(File.dirname(__FILE__), mo_file)
    Open3.popen2e("/opt/openmodelica/bin/omc -s " + mo_file + " Modelica", :chdir => directory) do |i, o, t|
      o.each {|l| puts l }
      status = t.value
      # p o.gets
    end
    Open3.popen2e("mv " + simulation_name + ".makefile Makefile", :chdir => directory) do |i, o, t|
      o.each {|l| puts l }
      status = t.value
      # p o.gets
    end
    Open3.popen2e("make", :chdir => directory) do |i, o, t|
      o.each {|l| puts l }
      status = t.value
      # p o.gets
    end

    Open3.popen2e("./" + simulation_name + " -override outputFormat='csv',variableFilter='pointMass.r.*',stopTime='5'",
                  :chdir => directory) do |i, o, t|
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
