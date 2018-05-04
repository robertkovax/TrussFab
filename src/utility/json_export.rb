require 'json'
require 'src/database/graph.rb'
require 'src/utility/geometry.rb'

# puts necessary parameters in json file for export
class JsonExport
  def self.export(path, triangle = nil, animation)
    file = File.open(path, 'w')
    file.write(graph_to_json(triangle, animation))
    file.close
  end

  def self.graph_to_json(triangle = nil, animation)
    graph = Graph.instance
    json = { distance_unit: 'mm', force_unit: 'N' }
    json[:nodes] = nodes_to_hash(graph.nodes)
    json[:edges] = edges_to_hash(graph.edges)
    json[:animation] = animation
    unless triangle.nil?
      json[:standard_surface] = triangle.nodes_ids_towards_user
    end
    JSON.pretty_generate(json)
  end

  def self.nodes_to_hash(nodes)
    nodes.map do |id, node|
      {
        id: id,
        x: node.position.x.to_mm,
        y: node.position.y.to_mm,
        z: node.position.z.to_mm,
        pods: node.pod_export_info
      }
    end
  end

  def self.edges_to_hash(edges)
    edges.map do |id, edge|
      {
        id: id,
        n1: edge.first_node.id,
        n2: edge.second_node.id,
        type: edge.link_type,
        bottle_type: edge.bottle_type
      }
    end
  end
end
