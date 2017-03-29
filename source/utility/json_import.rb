require 'json'
require ProjectHelper.database_directory + '/graph.rb'

class JsonImport
  def self.import path, position
    file = File.open path, 'r'
    json_string = file.read
    file.close
    from_string json_string, position
  end

  def self.from_string string, position
    json_objects = JSON.parse(string)
    unless json_objects.nil?
      nodes = build_nodes json_objects, position
      edges = build_edges json_objects, nodes
      create_surfaces edges
    end
    edges
  end

  # create surfaces from partners
  # we look at both first_node and second_node, since surfaces with a missing link can occur
  def self.create_surfaces edges
    surfaces = Hash.new
    edges.values.each do |edge|
      [edge.first_node, edge.second_node].each do |edge_node|
        edge_node.partners.each do |partner|
          node = partner[:node]
          next if node == edge.first_node or node == edge.second_node
          next if Graph.instance.duplicated_surface? [edge.first_node, edge.second_node, node]
          surface = Graph.instance.create_surface_from_nodes edge.first_node, edge.second_node, node
          surfaces[surface.id] = surface
        end
      end
    end
    surfaces
  end

  def self.build_nodes json_objects, position
    first = true
    translation = Geom::Transformation.new
    nodes = Hash.new
    json_objects['nodes'].each do |node|
      x = node['x'].to_f.mm
      y = node['y'].to_f.mm
      z = node['z'].to_f.mm
      point = Geom::Point3d.new x, y, z
      if first
        translation = point.vector_to position
        first = false
      end
      point.transform! translation
      nodes[node['id']] = point
    end
    nodes
  end

  def self.build_edges json_objects, nodes
    edges = Hash.new
    json_objects['edges'].each do |edge|
      first_node = nodes[edge['n1']]
      second_node = nodes[edge['n2']]
      link_type = edge['type']
      model_name = edge['model'].nil? ? 'hard' : edge['model']
      first_elongation_length = edge['e1'].nil? ? Configuration::DEFAULT_ELONGATION : edge['e1'].to_l
      second_elongation_length = edge['e2'].nil? ? Configuration::DEFAULT_ELONGATION : edge['e2'].to_l
      new_edge = Graph.instance.create_edge_from_points first_node, second_node, link_type, model_name,
                                                    first_elongation_length, second_elongation_length
      edges[edge['id']] = new_edge
    end
    edges
  end
end