require 'erb'
require 'csv'
require "rexml/document"
require 'rexml/xpath'
require 'rexml/formatters/pretty'

class ModellicaExport
  def self.export(path, initial_node)
    #graph_to_modellica(initial_node)
    nodes = Graph.instance.nodes

    # xml replacement approach:
    # override_simulation_specification(File.join(File.join(File.dirname(__FILE__), "seesaw3_build"), "seesaw3_init.xml"), nodes)

    @nodes = nodes.sort
    renderer = ERB.new(File.read(File.join(File.dirname(__FILE__), 'seesaw3.mo.erb')))

    file = File.open(File.join(File.dirname(__FILE__), 'seesaw3.mo'), 'w+')
    file.write(renderer.result(binding))
    file.close

    #file = File.open(File.join(File.dirname(__FILE__), 'TetrahedronSpring.mo'), 'w')
    #file.write(graph_to_modellica(initial_node))
    #file.close
  end

  def self.override_simulation_specification(path, nodes)
    text = File.read(path)

    nodes.each do | node_id, node |

      regex_x = /(name = "N\[#{Regexp.quote(node_id.to_s)},1\]")(.*?)(Real start=")\K([\d|.]*)/m
      text.gsub!(regex_x, node.position.x.to_m.to_f.to_s)
      regex_y = /(name = "N\[#{Regexp.quote(node_id.to_s)},2\]")(.*?)(Real start=")\K([\d|.]*)/m
      text.gsub!(regex_y, node.position.y.to_m.to_f.to_s)
      regex_z = /(name = "N\[#{Regexp.quote(node_id.to_s)},3\]")(.*?)(Real start=")\K([\d|.]*)/m
      text.gsub!(regex_z, node.position.z.to_m.to_f.to_s)

    end

    File.write(path, text)

    #doc = REXML::Document.new(File.open(path))
    ## nodes[8].position.z.to_m.to_f
    #
    #nodes.each do | node_id, node |
    #  search_path_x = "fmiModelDescription/ModelVariables/ScalarVariable[@name='N[#{node_id},1]']/Real/"
    #  REXML::XPath.each(doc, search_path_x) do |xml_node|
    #    xml_node.attributes['start'] = node.position.x.to_m.to_f
    #  end
    #  search_path_y = "fmiModelDescription/ModelVariables/ScalarVariable[@name='N[#{node_id},2]']/Real/"
    #  REXML::XPath.each(doc, search_path_y) do |xml_node|
    #    xml_node.attributes['start'] = node.position.y.to_m.to_f
    #  end
    #  search_path_z = "fmiModelDescription/ModelVariables/ScalarVariable[@name='N[#{node_id},3]']/Real/"
    #  REXML::XPath.each(doc, search_path_z) do |xml_node|
    #    xml_node.attributes['start'] = node.position.z.to_m.to_f
    #  end
    #end
    #
    ##REXML::XPath.each(doc, "Scalar") do |node|
    ##  puts(node.attributes["modelName"]) # => So and so
    ##  node.attributes["modelName"] = "Something else"
    ##  puts(node.attributes["modelName"]) # => Something else
    ##end
    #
    #doc.write(File.open(path, "r+"))
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

  def self.parameter_for_position(identifier, position)
    "parameter Real #{identifier}[3] = #{modelica_variable_for_position(position)};"
  end

  def self.modelica_variable_for_position(node)
    "{#{node.position.x.to_m.round(3).to_s}, #{node.position.y.to_m.round(3).to_s}, #{node.position.z.to_m.round(3).to_s}}"
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
