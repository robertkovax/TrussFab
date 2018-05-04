require 'singleton'
require 'src/simulation/simulation.rb'
require 'src/algorithms/rigidity_tester.rb'
require 'src/export/export_interface'
require 'src/export/static_group_analysis'

# Hinge Placement Algorithm
class HingePlacementAlgorithm
  include Singleton

  attr_accessor :export_interface

  def initialize
    @export_interface = nil
  end

  def run
    @export_interface = ExportInterface.new

    edges = Graph.instance.edges.values
    edges.each(&:reset)

    static_groups = StaticGroupAnalysis.find_static_groups
    static_groups.select! { |group| group.size > 1 }
    static_groups.sort! { |a, b| b.size <=> a.size }
    static_groups = prioritise_pod_groups(static_groups)

    group_rotations = Hash.new { |h, k| h[k] = Set.new }

    group_combinations = static_groups.combination(2)
    group_combinations.each do |pair|
      group1_edges = Set.new(pair[0].flat_map(&:edges))
      group2_edges = Set.new(pair[1].flat_map(&:edges))

      common_edges = group1_edges & group2_edges

      raise 'More than one common edge.' if common_edges.size > 1

      if !common_edges.empty? && common_edges.to_a[0].dynamic?
        group_rotations[pair[1]].add(pair[0])
        group_rotations[pair[0]].add(pair[1])
      end
    end

    group_edge_map = {}

    # generate hubs for all groups with size > 1
    processed_edges = Set.new
    static_groups.each do |group|
      group_nodes = Set.new(group.flat_map(&:nodes))
      group_edges = Set.new(group.flat_map(&:edges))
      group_edges -= processed_edges

      group_edge_map[group] = group_edges

      group_nodes.each do |node|
        hub_edges = group_edges.select { |edge| edge.nodes.include? node }

        # if hub only connects with two edges at this node,
        # it degenerates to a hinge
        if hub_edges.size == 2
          hinge = HingeExportInterface.new(hub_edges[0], hub_edges[1])
          @export_interface.add_hinge(node, hinge)
        else
          hub = HubExportInterface.new(hub_edges)
          @export_interface.add_hub(node, hub)
        end
      end

      processed_edges = processed_edges.merge(group_edges)
    end

    # put hinges everywhere possible
    triangles = Set.new(edges.flat_map(&:adjacent_triangles))

    triangles.each do |tri|
      tri.edges.combination(2).each do |e1, e2|
        same_group = static_groups.any? do |group|
          group_edge_map[group].include?(e1) &&
            group_edge_map[group].include?(e2)
        end

        next if same_group

        node = e1.shared_node(e2)
        hinge = HingeExportInterface.new(e1, e2)
        hinge.is_double_hinge = tri.dynamic?
        @export_interface.add_hinge(node, hinge)
      end
    end

    Sketchup.active_model.start_operation('find hinges', true)
    @export_interface.apply_hinge_algorithm
    Sketchup.active_model.commit_operation

    Sketchup.active_model.start_operation('elongate edges', true)
    @export_interface.elongate_edges
    Sketchup.active_model.commit_operation

    # add visualisations

    # shorten elongations for all edges that are not part of the main hub
    # nodes.each do |node|
    #   main_hub = @hubs[node][0]
    #
    #   node_edges = edges.select do |edge|
    #     edge.nodes.include?(node) && edge.link_type != 'actuator'
    #   end
    #
    #   node_edges.each do |edge|
    #     if main_hub.nil? || !main_hub.include?(edge)
    #       disconnect_edge_from_hub(edge, node)
    #     end
    #   end
    # end

    @export_interface.hinges.each do |hinge|
      visualize_hinge(hinge)
    end

    group_nr = 0
    Sketchup.active_model.start_operation('color static groups', true)
    static_groups.reverse.each do |group|
      color_group(group, group_nr)
      group_nr += 1
    end
    Sketchup.active_model.commit_operation

    hinge_layer = Sketchup.active_model.layers.at(Configuration::HINGE_VIEW)
    hinge_layer.visible = true
  end

  def color_group(group, group_nr)
    group_color = case group_nr
                  when 0
                    '1f78b4' # dark blue
                  when 1
                    'e31a1c' # dark red
                  when 2
                    'ff7f00' # dark orange
                  when 3
                    '984ea3' # purple
                  when 4
                    'a65628' # brown
                  when 5
                    'a6cee3' # light blue
                  when 6
                    'e78ac3' # pink
                  when 7
                    'fdbf6f' # light orange
                  else
                    format('%06x', rand * 0xffffff)
                  end

    group.each do |triangle|
      triangle.edges.each do |edge|
        edge.thingy.change_color(group_color)
      end
    end
  end

  def disconnect_edge_from_hub(rotating_edge, node)
    if rotating_edge.first_node?(node)
      rotating_edge.thingy.disconnect_from_hub(true)
    else
      rotating_edge.thingy.disconnect_from_hub(false)
    end
  end

  def visualize_hinge(hinge)
    rotation_axis = hinge.edge1
    rotating_edge = hinge.edge2
    node = rotating_edge.shared_node(rotation_axis)

    mid_point1 = Geom::Point3d.linear_combination(0.7,
                                                  node.position,
                                                  0.3,
                                                  rotation_axis.mid_point)
    mid_point2 = Geom::Point3d.linear_combination(0.7,
                                                  node.position,
                                                  0.3,
                                                  rotating_edge.mid_point)

    # Draw hinge visualization
    mid_point = Geom::Point3d.linear_combination(0.5, mid_point2,
                                                 0.5, mid_point1)

    if hinge.is_double_hinge
      mid_point = Geom::Point3d.linear_combination(0.75, mid_point,
                                                   0.25, node.position)
    end

    line1 = Line.new(mid_point, mid_point1, HINGE_LINE)
    line2 = Line.new(mid_point, mid_point2, HINGE_LINE)

    rotating_edge.thingy.add(line1, line2)
  end

  def prioritise_pod_groups(groups)
    pod_groups = groups.select do |group|
      group.any? { |tri| tri.nodes.all? { |node| node.thingy.pods? } }
    end
    pod_groups + (groups - pod_groups)
  end
end
