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

    check_for_only_simple_hinges static_groups

    static_groups.select! { |group| group.size > 1 }
    static_groups.sort! { |a, b| b.size <=> a.size }
    static_groups = prioritise_pod_groups(static_groups)

    @export_interface = NodeExportInterface.new(static_groups)

    group_edge_map = {}

    # generate hubs for all groups with size > 1
    static_groups.each do |group|
      group_nodes = Set.new(group.flat_map(&:nodes))
      group_edges = Set.new(group.flat_map(&:edges))

      group_edge_map[group] = group_edges

      group_nodes.each do |node|
        hub_edges = group_edges.select { |edge| edge.nodes.include? node }
        hub_edges = sort_edges_clockwise(hub_edges)

        hub = HubExportInterface.new(hub_edges)
        @export_interface.add_hub(node, hub)
      end
    end

    # put hinges everywhere possible
    triangles = Set.new(edges.flat_map(&:adjacent_triangles))

    triangles.each do |tri|
      tri.edges.combination(2).each do |e1, e2|
        hinge = generate_hinge_if_necessary(
          e1, e2, tri, static_groups, group_edge_map
        )

        node = e1.shared_node(e2)

        if !@export_interface.has_mainhub_at_node(node) &&
           !hinge.is_double_hinge
          hub = HubExportInterface.new([e1, e2])
          @export_interface.add_hub(node, hub)
        else
          @export_interface.add_hinge(node, hinge) unless hinge.nil?
        end
      end
    end

    @export_interface.apply_hinge_algorithm

    Sketchup.active_model.start_operation('elongate edges', true)
    ElongationManager.improve_elongations(@export_interface, nodes, false)
    Sketchup.active_model.commit_operation

    Sketchup.active_model.start_operation('visualize export result', true)
    NodeExportVisualization.visualize(@export_interface)
    Sketchup.active_model.commit_operation
  end

  private

  def edge_angle(edge1, edge2)
    edge1.direction.normalize.dot(edge2.direction.normalize).abs
  end

  # Make sure that if static groups touch, they touch at exactly 2 points,
  # otherwise, the structure will be bended, and not fabricateable with welding
  # (statement yet to proof)
  def check_for_only_simple_hinges static_groups
    static_groups_as_sets_of_node_ids = static_groups.map do |triangles|
      node_ids = Set.new
      triangles.each do |triangle|
        node_ids << triangle.first_node.id
        node_ids << triangle.second_node.id
        node_ids << triangle.third_node.id
      end
      puts node_ids
      node_ids
    end
    static_groups_as_sets_of_node_ids.product(static_groups_as_sets_of_node_ids) do |one, two|
      next if one == two
      difference_size = (one & two).size
      unless [0, 2].include? difference_size
        puts "Structure has hinges that won't be buildable "
      end
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
