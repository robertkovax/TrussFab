#!/usr/bin/env ruby

require 'csv'
require_relative './animation_data_sample.rb'
require 'open3'

RUBY_EXECUTABLE_WITH_GSL = 'ruby'

class SimulationRunner

  def initialize
    @directory = File.dirname(__FILE__)

    # TODO reenable next lines again!!!
    #Open3.popen2e("make compile", :chdir => @directory) do |i, o, t|
    #  o.each {|l| puts l }
    #  status = t.value
    #end
  end

  def get_hub_time_series(hubIDs, stepSize, mass, constant=50)
    data = []
    simulation_time = Benchmark.realtime { run_simulation(constant, mass, "node_pos.*") }
    import_time = Benchmark.realtime { data = import_csv(File.join(File.dirname(__FILE__), "seesaw3_res.csv")) }
    puts("simulation time: #{simulation_time.to_s}s csv parsing time: #{import_time.to_s}s")
    data
  end

  def get_period(mass=20, constant=50000)
    run_simulation(constant, mass, "revLeft.phi")
    # Since Sketchup makes Installation of Gems really hard, we have to run the script in an ruby environement somewhere outside
    output, signal = Open3.capture2e("#{RUBY_EXECUTABLE_WITH_GSL} -r ./simulation_runner.rb -e \"p SimulationRunner.get_period_from_file\"", :chdir => @directory)
    p output
    p output.to_f
    output.to_f
  end


  def self.get_period_from_file()
    require 'gsl'
    require 'csv'

    stop_time = 10

    data = CSV.read((File.join(File.dirname(__FILE__), "seesaw3_res.csv")), :headers=>true)['revLeft.phi']
    vector = data.map{ |v| v.to_f }.to_gv

    sample_rate = vector.length / stop_time

    # https://github.com/SciRuby/rb-gsl/blob/master/examples/fft/fft.rb
    y2 = vector.fft.subvector(1, data.length - 2).to_complex2
    mag = y2.abs
    f = GSL::Vector.linspace(0, sample_rate/2, mag.size)
    #p mag.to_a
    #p mag.max_index
    #p f.to_a
    return 1 / f[mag.max_index]
  end

  def find_equilibrium(mass=20, constant=50)
    # run simulation mit startTime 0.3; get first frame
    run_simulation(constant, mass, "node_pos.*")
    import_csv(File.join(File.dirname(__FILE__), "seesaw3_res.csv"))

    #mocked_position_data = {"1"=>Geom::Point3d.new(0, 0, 0.748031), "2"=>Geom::Point3d.new(26.3386, 0, 0.748031), "3"=>Geom::Point3d.new(13.189, 22.8346, 0.748031), "4"=>Geom::Point3d.new(39.3307, 11.1811, 20.7874), "5"=>Geom::Point3d.new(4.48819, 12.5197, 23.4646), "6"=>Geom::Point3d.new(21.1417, -7.83465, 22.5197), "7"=>Geom::Point3d.new(22.4803, 31.378, 20.8661), "8"=>Geom::Point3d.new(42.5197, 19.8031, 0.551181), "9"=>Geom::Point3d.new(43.3376, -12.6202, 9.80675), "10"=>Geom::Point3d.new(-1.66332, 36.4207, 13.9296), "11"=>Geom::Point3d.new(57.1895, -5.2645, 31.0651), "12"=>Geom::Point3d.new(34.7027, -0.466413, 43.951), "13"=>Geom::Point3d.new(38.8624, -24.0667, 33.0068), "14"=>Geom::Point3d.new(7.85218, 47.7481, 35.3248), "15"=>Geom::Point3d.new(-10.4259, 28.9441, 37.8413), "16"=>Geom::Point3d.new(14.5224, 24.1121, 44.8706), "17"=>Geom::Point3d.new(61.3135, -28.9076, 20.0817), "18"=>Geom::Point3d.new(61.4532, -26.3095, 66.3204), "19"=>Geom::Point3d.new(-16.9368, 52.5334, 27.9541), "20"=>Geom::Point3d.new(-11.0442, 50.1143, 53.5318)}
    #AnimationDataSample.new(0.0, mocked_position_data)
  end


  private

  def run_simulation(constant, mass, filter="*")
    # TODO adjust sampling rate dynamically
    overrides = "outputFormat='csv',variableFilter='#{filter}',startTime=0.3,stopTime=10,stepSize=0.02,springDamperParallel1.c='#{constant}'"
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
 #p 'yo'
 #p runner.get_period(70,60)