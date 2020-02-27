require 'src/system_simulation/trace_visualization.rb'

# Enables users to drag a line starting from a node to demonstrate the amplitude they want for the oscillation.
class DemonstrateAmplitudeTool < Tool
  def initialize(ui)
    super(ui)
    @mouse_input = MouseInput.new(snap_to_edges: true, snap_to_nodes: true)

    @start_node = nil
    @start_position = nil
    @end_position = nil
    @moving = false

    @simulation_runner = nil
  end

  def activate
    # Instantiates SimulationRunner and compiles model.
    @simulation_runner = @ui.spring_pane.try_compile
  end

  def onLButtonDown(_flags, x, y, view)
    @mouse_input.update_positions(view, x, y)
    obj = @mouse_input.snapped_object
    return if obj.nil? || !obj.is_a?(Node)

    @moving = true
    @start_node = obj
    @start_position = @end_position = obj.position
  end

  def onMouseMove(_flags, x, y, view)
    update(view, x, y)
  end

  def onLButtonUp(_flags, x, y, view)
    update(view, x, y)
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

  # TODO: probably a bit inefficient, we should think about a hash like data structure to store springs for static groups
  # Returns the spring that makes the static group the node is in movable.
  def relevant_spring_id_for_node(node)
    static_groups = StaticGroupAnalysis.get_static_groups_for_node(node)
    raise 'No static groups detected' unless static_groups

    static_group = static_groups[0]
    all_spring_edges = Graph.instance.edges.values.select { |edge| edge.link_type == 'spring' }
    spring_edges = all_spring_edges.select do |spring_edge|
      static_group.include?(spring_edge.first_node) || static_group.include?(spring_edge.second_node)
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
