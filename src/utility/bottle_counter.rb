require 'src/configuration/configuration.rb'

# counts bottles
class BottleCounter
  class << self
    def update_status_text
      bottle_status = '('
      bottle_counts.each do |name, count|
        bottle_status += "#{name}: #{count}  "
      end
      bottle_status.chop!.chop!
      bottle_status += ')'
      Sketchup.status_text = "Hubs: #{number_nodes} | Bottles: #{number_edges}"\
                             "#{bottle_status}"
    end

    def number_nodes
      Graph.instance.nodes.length
    end

    def number_edges
      Graph.instance.edges.length
    end

    def number_triangles
      Graph.instance.triangles.length
    end

    def number_actuators
      Graph.instance.edges.values.count { |edge| edge.link_type == 'actuator' }
    end

    def bottle_counts
      counts = {}
      ModelStorage.instance.models['hard'].models.values.each do |model|
        counts[model.short_name] = 0
      end
      Graph.instance.edges.values.each do |edge|
        if edge.link_type == 'bottle_link'
          counts[edge.link.bottle_link.model.short_name] += 1
        end
      end
      counts.select{ |_,num| num > 0}
    end
  end
end
