require 'json'
require 'src/database/graph.rb'
require 'src/utility/geometry.rb'
require 'src/utility/scheduler'

class JsonExport
  def self.export(path, triangle=nil)
    file = File.open(path, 'w')
    file.write(graph_to_json(triangle))
    file.close
  end

  def self.graph_to_json(triangle=nil)
    graph = Graph.instance
    json = {
      :distance_unit=>"mm",
      :force_unit=>"N"
    }
    json[:nodes] = nodes_to_hash(graph.nodes)
    json[:edges] = edges_to_hash(graph.edges)
    json[:standard_surface] = triangle.nodes_ids_towards_user if !triangle.nil?
    json[:schedules] = schedules_to_hash
    JSON.pretty_generate(json)
  end

  def self.nodes_to_hash(nodes)
    nodes.map do |id, node|
      {
        :id => id,
        :x => node.position.x.to_mm,
        :y => node.position.y.to_mm,
        :z => node.position.z.to_mm
      }
    end
  end

  def self.edges_to_hash(edges)
    edges.map do |id, edge|
      piston_group = nil
      if edge.link_type == 'actuator'
        piston_group = edge.thingy.piston_group
      end
      {
        :id => id,
        :n1 => edge.first_node.id,
        :n2 => edge.second_node.id,
        :piston_group => piston_group
      }
    end
  end

  def self.schedules_to_hash
    schedule_hash = {}
    Scheduler.instance.groups.each do |id, (_, schedule, _) |
      schedule_hash[id] = schedule
    end
    schedule_hash
  end
end
