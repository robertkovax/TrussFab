require 'src/configuration/configuration.rb'

# counts bottles
class BottleCounter
  class << self
    def update_status_text
      # It should tell the number of small-small, small-big, big-big, and hubs.
      Sketchup.status_text = "Hubs: #{number_nodes} | Bottles: #{number_edges}"\
                             " (small-small: #{number_small_small}  "\
                             "small-big: #{number_small_big}  "\
                             "big-big: #{number_big_big})"
    end

    def number_nodes
      Graph.instance.nodes.length
    end

    def number_edges
      Graph.instance.edges.length
    end

    def number_triangles
      Graph.instance.surfaces.length
    end

    def number_actuators
      Graph.instance.edges.values.count { |edge| edge.link_type == 'actuator' }
    end

    def bottle_counts
      counts = {}
      Configuration::HARD_MODELS.each do |model|
        counts[model[:NAME]] = 0
      end
      Graph.instance.edges.values.each do |edge|
        if edge.link_type == 'bottle_link'
          counts[edge.thingy.bottle_link.model.name] += 1
        end
      end
      counts
    end

    def number_small_small
      bottle_counts[Configuration::SMALL_SMALL_BOTTLE_NAME]
    end

    def number_small_big
      bottle_counts[Configuration::SMALL_BIG_BOTTLE_NAME]
    end

    def number_big_big
      bottle_counts[Configuration::BIG_BIG_BOTTLE_NAME]
    end
  end
end
