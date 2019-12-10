require 'erb'
require 'csv'
require 'src/animation_data_sample.rb'

class ModellicaExport
  def self.export(path, initial_node)
    file = File.open(File.join(File.dirname(__FILE__), 'TetrahedronSpring.mo'), 'w')
    file.write(graph_to_modellica(initial_node))
    file.close
  end

  def self.import_csv(file)
    raw_data = CSV.read(File.join(File.dirname(__FILE__), file))

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
    puts indices_map

    return data_samples

  end

  def self.graph_to_modellica(initial_node)
    graph = Graph.instance
    nodes = graph.nodes.map{|node| Geom::Point3d.new(node[1].position)}

    # graph does not contain initial node
    return unless (nodes.find(initial_node.position))

    # assuming a very constrained input graph, only containing one tetrahedron
    @n2 = Geom::Point3d.new(initial_node.position)
    nodes.delete(@n2)
    @n1 = nodes.find { |node| (initial_node.position.z - node.z).abs <= 0.1}
    @@offset = @n1
    nodes.delete(@n1)
    @n3 = nodes.find { |node| (initial_node.position.z - node.z).abs <= 0.1}
    nodes.delete(@n3)
    @n4 = nodes[0]

    @@offset_vector = @n1.vector_to(Geom::Point3d.new(0,0,0))

    @n1.offset!(@@offset_vector)
    @n2.offset!(@@offset_vector)
    @n3.offset!(@@offset_vector)
    @n4.offset!(@@offset_vector)

    # File.join(File.dirname(__FILE__),
    #           '../force-chart/sensor_overview.erb')
    renderer = ERB.new(File.read(File.join(File.dirname(__FILE__), 'TetrahedronSpring.erb')))
    # puts output = renderer.result(binding)
    return renderer.result(binding)


    # nodes.each do |id, node|
    #     puts("x: " +  node.position.x.to_m.to_s)
    #     puts("y: " +  node.position.y.to_m.to_s)
    #     puts("z: " +  node.position.z.to_m.to_s)
    # end
  end

  def self.string_for_position(identifier, position)
    "parameter Real #{identifier}[3] = {#{position.x.to_m.to_s}, #{position.y.to_m.to_s}, #{position.z.to_m.to_s}};"
  end

  def self.modelica_to_trussfab(data)
    if not defined?(@@offset_vector)
      @@offset_vector = Geom::Vector3d.new()
    end
    data.map do |line|
      # line[0] contains the timestamp whereas line[1] - line[3] contain the coordinates respectively
      position = Geom::Point3d.new(line[1].to_f().mm * 1000, line[2].to_f().mm * 1000, line[3].to_f().mm * 1000)
      position.offset!(@@offset_vector.reverse)
      [line[0], position.x, position.y, position.z]
    end
  end

end
