require 'erb'
require 'csv'
require 'src/animation_data_sample.rb'
require "rexml/document"
require 'rexml/xpath'
require 'rexml/formatters/pretty'

class ModellicaExport
  def self.export(path, initial_node)
    #graph_to_modellica(initial_node)
    nodes = Graph.instance.nodes
    override_simulation_specification(File.join(File.dirname(__FILE__), "seesaw3_init.xml"), nodes)
    #file = File.open(File.join(File.dirname(__FILE__), 'TetrahedronSpring.mo'), 'w')
    #file.write(graph_to_modellica(initial_node))
    #file.close
  end

  def self.import_csv(file)
    raw_data = CSV.read(File.join(File.join(File.dirname(__FILE__), "seesaw3"), file))

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

  def self.override_simulation_specification(path, nodes)
    doc = REXML::Document.new(File.open(path))
    # nodes[8].position.z.to_m.to_f

    nodes.each do | node_id, node |
      search_path_x = "fmiModelDescription/ModelVariables/ScalarVariable[@name='N[#{node_id},1]']/Real/"
      REXML::XPath.each(doc, search_path_x) do |xml_node|
        xml_node.attributes['start'] = node.position.x.to_m.to_f
      end
      search_path_y = "fmiModelDescription/ModelVariables/ScalarVariable[@name='N[#{node_id},2]']/Real/"
      REXML::XPath.each(doc, search_path_y) do |xml_node|
        xml_node.attributes['start'] = node.position.y.to_m.to_f
      end
      search_path_z = "fmiModelDescription/ModelVariables/ScalarVariable[@name='N[#{node_id},3]']/Real/"
      REXML::XPath.each(doc, search_path_z) do |xml_node|
        xml_node.attributes['start'] = node.position.z.to_m.to_f
      end
    end

    #REXML::XPath.each(doc, "Scalar") do |node|
    #  puts(node.attributes["modelName"]) # => So and so
    #  node.attributes["modelName"] = "Something else"
    #  puts(node.attributes["modelName"]) # => Something else
    #end

    doc.write(File.open(path, "r+"))
  end

  def self.graph_to_modellica(initial_node)
    #doc = File.open(File.join(File.dirname(__FILE__), "seesaw3_res.csv")) { |f| Nokogiri::XML(f) }

    #file = File.new( "mydoc.xml" )

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

  def self.map_nodes_to_ids(graph)
    #graph
  end

end
