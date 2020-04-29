require 'src/tools/pull_node_interaction_tool.rb'
require 'src/system_simulation/trace_visualization.rb'

# Enables users to drag a line starting from a node to demonstrate the amplitude they want for the oscillation.
class DemonstrateAmplitudeTool < PullNodeInteractionTool
  def initialize(ui)
    super(ui)

    @simulation_runner = nil
  end

  def activate
    # Instantiates SimulationRunner and compiles model.
    @simulation_runner = @ui.spring_pane.request_compilation
  end

  def onLButtonUp(_flags, x, y, view)
    super
    return unless @moving
    return if @start_node.nil?

    hinge_edge = get_hinge_edge(@start_node)
    hinge_center = hinge_edge.mid_point

    initial_vector = @start_position - hinge_center
    max_amplitude_vector = @end_position - hinge_center
    # user inputs only half of the amplitude since we want to have the oscillation symmetric around the equililbirum.
    angle = 2 * initial_vector.angle_between(max_amplitude_vector)

    spring_id = relevant_spring_id_for_node(@start_node)
    constant = @simulation_runner.constant_for_constrained_angle(angle, spring_id)
    @ui.spring_pane.update_constant_for_spring(spring_id, constant)

    view.invalidate
    reset
  end

  private

  # TODO: Probably a bit inefficient, we should think about a hash like data structure to store springs for
  # TODO: static groups.
  # Returns the spring that makes the static group the node is in movable.
  def relevant_spring_id_for_node(node)
    static_groups = StaticGroupAnalysis.get_static_groups_for_node(node)
    raise 'No static groups detected' unless static_groups

    all_spring_edges = Graph.instance.edges.values.select { |edge| edge.link_type == 'spring' }

    # get all springs that are connected to one of the static groups the node is in
    spring_edges = all_spring_edges.select do |spring_edge|
      static_groups.any? do |static_group|
        static_group.include?(spring_edge.first_node) || static_group.include?(spring_edge.second_node)
      end
    end
    raise 'no spring found for group' if spring_edges.empty?
    raise 'more than one spring found for group' if spring_edges.size > 1

    spring_edges[0].id
  end

  def get_hinge_edge(node)
    all_static_groups = StaticGroupAnalysis.find_static_groups
    static_groups_with_node = StaticGroupAnalysis.get_static_groups_for_node(node)
    raise 'No static group found.' unless static_groups_with_node

    # get first static group the node is in, should be only one anyways
    nodes = static_groups_with_node[0]
    rotary_hinge_pairs = NodeExportAlgorithm.instance.check_for_only_simple_hinges all_static_groups
    rotary_hinge_pairs.select! do |node_pair|
      nodes.include?(node_pair[0]) && nodes.include?(node_pair[1])
    end
    # rotary hinge paris contain duplicates (for each hinge both directions), we can just use the first one
    Graph.instance.find_edge(rotary_hinge_pairs[0])
  end
end
