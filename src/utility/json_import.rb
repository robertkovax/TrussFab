require 'json'
require 'src/database/graph.rb'

module JsonImport
  def self.import(path, position)
    file = File.open(path, 'r')
    json_string = file.read
    file.close
    from_string(json_string, position)
  end

  def self.from_string(string, position)
    json_objects = JSON.parse(string)
    unless json_objects.nil?
      nodes = build_nodes(json_objects, position)
      edges = build_edges(json_objects, nodes)
      create_surfaces(edges)
    end
    edges
  end

  # create surfaces from incidents
  # we look at both first_node and second_node, since surfaces with a missing link can occur
  def self.create_surfaces(edges)
    surfaces = {}
    edges.each do |edge|
      [edge.first_node, edge.second_node].each do |edge_node|
        edge_node.incidents.each do |incident|
          node = incident[:node]
          other_edge_node =
            if edge.first_node == edge_node
              edge.second_node
            else
              edge.first_node
            end
          next if node == edge.first_node ||
                  node == edge.second_node ||
                  Graph.instance.find_surface([edge.first_node, edge.second_node, node])
          next unless other_edge_node.is_adjacent(node)
          surface = Graph.instance.create_surface(edge.first_node, edge.second_node, node)
          surfaces[surface.id] = surface
        end
      end
    end
    surfaces
  end

  def self.build_nodes(json_objects, position)
    first = true
    translation = Geom::Transformation.new
    nodes = {}
    json_objects['nodes'].each do |node|
      x = node['x'].to_f.mm
      y = node['y'].to_f.mm
      z = node['z'].to_f.mm
      point = Geom::Point3d.new(x, y, z)
      if first
        translation = point.vector_to(position)
        first = false
      end
      point.transform!(translation)
      nodes[node['id']] = point
    end
    nodes
  end

  def self.build_edges(json_objects, nodes)
    edges = {}
    json_objects['edges'].each do |edge|
      first_node = nodes[edge['n1']]
      second_node = nodes[edge['n2']]
      link_type = edge['type']
      model_name = edge['model'].nil? ? 'hard' : edge['model']
      new_edge = Graph.instance.create_edge_from_points(first_node, second_node, model_name: model_name, link_type: link_type)
      edges[edge['id']] = new_edge
    end
    edges
  end
end
