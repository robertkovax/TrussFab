module ElongationManager

  def self.improve_elongations(export_interface)
    Manager.new(export_interface).perform
  end

  class Manager
    def initialize(export_interface)
      @export_interface = export_interface
    end

    def perform
      Edge.enable_bottle_freeze
      optimize_elongations
      Edge.disable_bottle_freeze
    end

    private

    def optimize_elongations
      l2 = PRESETS::L2
      l3_min = PRESETS::L3_MIN

      nodes = Graph.instance.nodes.values

      # find out all edges that need to be elongated and their corresponding node
      elongated_edge_map = Hash.new { |h, k| h[k] = Hash.new {
        |h,k| h[k] = Configuration::MINIMUM_ELONGATION } }

      # Set target elongation lengths for main hub edges , based on the smallest
      # angle to the nearest other edge
      nodes.each do |node|
        next if @export_interface.hubs_at_node(node).empty?
        mainhub = @export_interface.mainhub_at_node(node)

        mainhub.edges.each do |edge|
          angle = shortest_angle_for_edge(edge, node)
          length = determine_elongation_length(angle)
          elongated_edge_map[edge][node] =
            [elongated_edge_map[edge][node], length].max
        end
      end

      # Set target elongation lengths for subhub and hinge edges, based on
      # l1, l2 and l3 distances of the subhubs and hinges
      nodes.each do |node|
        subhubs = @export_interface.subhubs_at_node(node)
        hinges = @export_interface.hinges_at_node(node)

        # edges that are part of a subhub need to be elongated
        elongated_edges = subhubs.map(&:edges).flatten
        # edges that are connected by hinges also need to be elongated
        elongated_edges += hinges.map { |hinge| [hinge.edge1, hinge.edge2] }
                                 .flatten
        elongated_edges.uniq!
        # don't elongated edges that have a dynamic size
        elongated_edges.reject!(&:dynamic?)

        l1 = @export_interface.l1_at_node(node)
        target_length = l1 + l2 + l3_min
        elongated_edges.each do |edge|
          elongated_edge_map[edge][node] =
            [elongated_edge_map[edge][node], target_length].max
        end
      end

      elongate_edges_with_tuples(elongated_edge_map)
    end

    def elongate_edges_with_tuples(elongated_edge_map)
      loop do
        relaxation = Relaxation.new
        is_finished = true

        elongated_edge_map.each do |edge, node_length_map|
          if set_elongations_for_edge(relaxation, edge, node_length_map)
            is_finished = false
          end
        end

        break if is_finished

        relaxation.relax
      end
    end

    def set_elongations_for_edge(relaxation, edge, node_length_map)
      # if pods are fixed and edge can not be elongated, raise error
      edge_fixed = edge.nodes.any?(&:fixed?)
      if edge_fixed
        raise "#{edge.inspect} is fixed, e.g. by a pod, but needs to be "\
              'elongated since a hinge connects to it.'
      end

      new_first_elongation_length = edge.first_elongation_length
      new_second_elongation_length = edge.second_elongation_length

      node_length_map.each do |node, target_length|
        if node == edge.first_node
          new_first_elongation_length = target_length
        elsif node == edge.second_node
          new_second_elongation_length = target_length
        else
          raise 'Logic error during node export: '\
                'Node ' + node.to_s + ' is not connected to edge ' + edge.to_s
        end
      end

      if new_first_elongation_length <= edge.first_elongation_length &&
         new_second_elongation_length <= edge.second_elongation_length
        return false
      end

      total_old_elongation =
        edge.first_elongation_length + edge.second_elongation_length

      total_new_elongation =
        new_first_elongation_length + new_second_elongation_length

      edge.link.elongation_ratio =
        new_first_elongation_length / total_new_elongation

      relaxation.stretch_to(edge,
                            edge.length - total_old_elongation +
                            total_new_elongation + 10.mm)

      true
    end

    def vector_facing_away(edge, node)
      if node == edge.first_node
        edge.direction
      else
        edge.direction.reverse
      end
    end

    def shortest_angle_for_edge(edge, node)
      other_edges = node.incidents.reject { |other_edge| other_edge == edge }
      angles = other_edges.map do |other_edge|
        vector_a = vector_facing_away(edge, node)
        vector_b = vector_facing_away(other_edge, node)
        vector_a.angle_between(vector_b)
      end
      angles.min
    end

    def determine_elongation_length(angle)
      return Configuration::MINIMUM_ELONGATION if angle > Math::PI
      e = Math.sqrt(Configuration::CONNECTOR_CUFF_RADIUS *
                    Configuration::CONNECTOR_CUFF_RADIUS *
                    2 * (1 - Math::cos(angle)))
      gamma = (Math::PI - angle) / 2
      (e * Math::sin(gamma) / Math::sin(angle)).mm
    end
  end
end
