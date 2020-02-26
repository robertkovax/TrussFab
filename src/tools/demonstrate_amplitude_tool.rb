require_relative 'spring_simulation_tool.rb'
require 'src/system_simulation/trace_visualization.rb'

# Enables users to drag a line starting from a node to demonstrate the amplitude they want for the oscillation.
class DemonstrateAmplitudeTool < SpringSimulationTool
  def initialize(ui)
    super(ui)
    @mouse_input = MouseInput.new(snap_to_edges: true, snap_to_nodes: true)

    @start_node = nil
    @start_position = nil
    @end_position = nil
    @moving = false

    @trace_visualization = TraceVisualization.new
  end

  def onLButtonDown(_flags, x, y, view)
    @mouse_input.update_positions(view, x, y)
    obj = @mouse_input.snapped_object
    return if obj.nil? || !obj.is_a?(Node)

    @moving = true
    @start_node = obj
    @start_position = @end_position = obj.position

    @trace_visualization.reset_trace
  end

  def onMouseMove(_flags, x, y, view)
    update(view, x, y)
  end

  def onLButtonUp(_flags, x, y, view)
    update(view, x, y)
    return unless @moving
    return if @start_node.nil?

    hinge_center = get_hinge_edge(@start_node).mid_point
    initial_vector = @start_position - hinge_center
    max_amplitude_vector = @end_position - hinge_center
    # user inputs only half of the amplitude since we want to have the oscillation symmetric around the equililbirum.
    angle = 2 * initial_vector.angle_between(max_amplitude_vector)

    @constant = @simulation_runner.constant_for_constrained_angle(angle)

    simulate
    equilibrium_index = @simulation_runner.find_equilibrium(@constant)
    set_graph_to_data_sample(equilibrium_index)
    @trace_visualization.add_trace(['18', '20'], 4, @simulation_data)

    view.invalidate
    reset
  end

  def update(view, x, y)
    @mouse_input.update_positions(view, x, y, point_on_plane_from_camera_normal: @start_position || nil)

    return unless @moving && @mouse_input.position != @end_position

    @end_position = @mouse_input.position
    view.invalidate
  end

  def reset
    @start_node = nil
    @start_position = nil
    @end_position = nil
    @moving = false
  end

  def draw(view)
    return unless @moving

    view.line_stipple = ''
    view.line_width = 7
    view.drawing_color = 'black'
    view.draw_lines(@start_position, @end_position)
  end

  private

  def get_hinge_edge(node)
    all_static_groups = StaticGroupAnalysis.find_static_groups
    static_groups_with_node = StaticGroupAnalysis.get_static_groups_for_node(node)

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
