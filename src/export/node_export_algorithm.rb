require 'singleton'
require 'src/simulation/simulation.rb'
require 'src/algorithms/rigidity_tester.rb'
require 'src/export/node_export_interface'
require 'src/export/static_group_analysis'
require 'src/export/node_export_visualization'
require 'src/export/elongation_manager'

# This class determines the placement of hubs, subhubs and hinges.
# For finding out hinge positions, static group analysis is used.
# Also edges that are connected to hinges or subhubs are elongated
# to make room for the connection.
class NodeExportAlgorithm
  include Singleton

  attr_reader :export_interface

  def initialize
    @export_interface = nil
  end

  def run
    nodes = Graph.instance.nodes.values
    edges = Graph.instance.edges.values

    static_groups = StaticGroupAnalysis.find_static_groups

    rotary_hinge_pairs = check_for_only_simple_hinges static_groups
    offset_rotary_hinge_hubs(rotary_hinge_pairs, static_groups)

    # static_groups.select! { |group| group.size > 1 }
    # static_groups.sort! { |a, b| b.size <=> a.size }
    # static_groups = prioritise_pod_groups(static_groups)
    #
    # @export_interface = NodeExportInterface.new(static_groups)
    #
    # group_edge_map = {}
    #
    # # generate hubs for all groups with size > 1
    # static_groups.each do |group|
    #   group_nodes = Set.new(group.flat_map(&:nodes))
    #   group_edges = Set.new(group.flat_map(&:edges))
    #
    #   group_edge_map[group] = group_edges
    #
    #   group_nodes.each do |node|
    #     hub_edges = group_edges.select { |edge| edge.nodes.include? node }
    #     hub_edges = sort_edges_clockwise(hub_edges)
    #
    #     hub = HubExportInterface.new(hub_edges)
    #     @export_interface.add_hub(node, hub)
    #   end
    # end

    # put hinges everywhere possible
    # triangles = Set.new(edges.flat_map(&:adjacent_triangles))
    #
    # triangles.each do |tri|
    #   tri.edges.combination(2).each do |e1, e2|
    #     hinge = generate_hinge_if_necessary(
    #       e1, e2, tri, static_groups, group_edge_map
    #     )
    #
    #     node = e1.shared_node(e2)
    #
    #     if !@export_interface.has_mainhub_at_node(node) &&
    #        !hinge.is_double_hinge
    #       hub = HubExportInterface.new([e1, e2])
    #       @export_interface.add_hub(node, hub)
    #     else
    #       @export_interface.add_hinge(node, hinge) unless hinge.nil?
    #     end
    #   end
    # end

    # @export_interface.apply_hinge_algorithm

    # Sketchup.active_model.start_operation('elongate edges', true)
    # ElongationManager.improve_elongations(@export_interface, nodes, false)
    # Sketchup.active_model.commit_operation

    # Sketchup.active_model.start_operation('visualize export result', true)
    # NodeExportVisualization.visualize(@export_interface)
    # Sketchup.active_model.commit_operation

  end

  private

  def offset_rotary_hinge_hubs(rotary_hinges, static_groups)
    static_groups_as_sets_of_nodes = map_to_set_of_nodes static_groups
    rotary_hinges.each do |node_pair|

      if node_pair.length != 2
        raise "Expected #{node_pair} to only contain two hinges, we currently
don't handle the case of > 2 nodes on one rotation axis"
      end

      static_groups_pair =
        static_groups_as_sets_of_nodes
        .select { |node_set| node_pair.all? { |node| node_set.include?(node) } }

      if static_groups_pair.length != 2
        raise "Expected #{static_groups_pair} to only contain two static groups
 to rotate around one hinge. Currently we don't support more than two moving
structures at the same hinge"
      end

      substructure_to_inset = choose_structure_to_inset static_groups_pair.to_a

      node_pair.each do |node_to_inset|
        other_node_to_inset = if node_pair[0] == node_to_inset
                                node_pair[1]
                              else
                                node_pair[0]
                              end

        edges_from_hinge_into_inset = node_to_inset.incidents.select { |edge| substructure_to_inset.include? edge.other_node(node_to_inset) }.select { |edge| edge.opposite(node_to_inset) != other_node_to_inset }
        nodes_to_reconnect_to = edges_from_hinge_into_inset.map { |edge| { :node =>  edge.opposite(node_to_inset), :type => edge.link_type} }

        edges_from_hinge_into_inset.each(&:delete)

        inset_vector = node_to_inset.position.vector_to(other_node_to_inset.position)
        inset_vector.length = Configuration::DISTANCE_TO_INSET_ROTARY_HUBS
        inset_position = node_to_inset.position + inset_vector

        nodes_to_reconnect_to.each do |node_information|
          edge = Graph.instance.create_edge_from_points(inset_position, node_information[:node].position, link_type: node_information[:type])

        end
      end
    end
  end

  def choose_structure_to_inset(static_groups_pair)
    # 1. Criterion: Offset which has no pods
    has_pods = static_groups_pair.map do |static_group|
      static_group.to_a.any? { |node| !node.pods.empty? }
    end
    return static_groups_pair[0] if !has_pods[0] && has_pods[1]
    return static_groups_pair[1] if has_pods[0] && !has_pods[1]

    # 2. Criterion: Number of nodes
    if static_groups_pair[0].size > static_groups_pair[1].size
      static_groups_pair[1]
    else
      static_groups_pair[0]
    end
  end

  def edge_angle(edge1, edge2)
    edge1.direction.normalize.dot(edge2.direction.normalize).abs
  end

  # Make sure that if static groups touch, they touch at exactly 2 points,
  # otherwise, the structure will be bended, and not fabricateable with welding
  # (Actually, it would be okay to have more than 2 touching points, of which
  # all lie on the same rotation axis. We don't consider that case right now)
  def check_for_only_simple_hinges(static_groups)
    rotary_hinges = []
    static_groups_as_sets_of_nodes = map_to_set_of_nodes static_groups
    static_groups_as_sets_of_nodes.product(static_groups_as_sets_of_nodes) do |one, two|
      next if one == two

      difference = (one & two)

      if difference.size == 2
        rotary_hinges.push(difference.to_a)
      elsif difference.size != 0
        puts 'Structure has hinges that might not be buildable\n
This error can wrongly occure if rotary hinge hubs lie on the
same rotation axis'
      end
    end
    rotary_hinges
  end

  # Takes an array of triangles in static groups, and maps them to an array
  # of sets, which contain the nodes in the static groups
  def map_to_set_of_nodes(static_groups)
    static_groups.map do |triangles|
      nodes = Set.new
      triangles.each do |triangle|
        nodes << triangle.first_node
        nodes << triangle.second_node
        nodes << triangle.third_node
      end
      nodes
    end
  end

  # HACK: always choose the next edge, that has the minimum angle to the current
  # one. For the cases we encountered so far this works.
  def sort_edges_clockwise(edges)
    result = []
    current = edges[0]

    loop do
      result.push(current)
      return result if result.size == edges.size
      remaining_edges = edges - result

      current = remaining_edges.min do |a, b|
        edge_angle(b, current) <=> edge_angle(a, current)
      end
    end

    raise 'Sorting edges failed.'
  end

  def generate_hinge_if_necessary(edge1, edge2, tri, static_groups, group_edges)
    is_same_group = static_groups.any? do |group|
      group_edges[group].include?(edge1) &&
        group_edges[group].include?(edge2)
    end

    return nil if is_same_group

    is_double_hinge = tri.dynamic?
    HingeExportInterface.new(edge1, edge2, is_double_hinge)
  end

  def prioritise_pod_groups(groups)
    pod_groups = groups.select do |group|
      group.any? { |tri| tri.nodes.all? { |node| node.hub.pods? } }
    end
    pod_groups + (groups - pod_groups)
  end
end
