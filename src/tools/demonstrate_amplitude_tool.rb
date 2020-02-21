require_relative 'spring_simulation_tool.rb'
require 'src/system_simulation/trace_visualization.rb'

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
    if !obj.nil? && obj.is_a?(Node) # && obj.link_type == 'spring'
      @moving = true
      @start_node = obj
      @start_position = @end_position = obj.position

      @trace_visualization.reset_trace
    end
  end

  def onMouseMove(_flags, x, y, view)
    update(view, x, y)
  end

  def onLButtonUp(_flags, x, y, view)
    update(view, x, y)
    return unless @moving
    return if @start_node.nil?
    puts @end_position

    hinge = get_mock_hinge_information
    initial_vector = @start_position - hinge[:hinge_center]
    max_amplitude_vector = @end_position - hinge[:hinge_center]
    # user inputs only half of the amplitude since we want to have the oscillation symmetric around the equililbirum.
    angle = 2 * initial_vector.angle_between(max_amplitude_vector)

    @constant = @simulation_runner.optimize_constant_for_constrained_angle(angle)

    simulate
    equilibrium_index = @simulation_runner.find_equilibrium(@constant)
    set_graph_to_data_sample(equilibrium_index)
    @trace_visualization.add_trace(["18", "20"], 4, @simulation_data)


    puts initial_vector
    puts max_amplitude_vector
    puts angle
    puts @constant
    #model = Sketchup.active_model
    #entities = model.active_entities
    #point1 = hinge[:hinge_center]
    #point2 = @end_position
    #constline = entities.add_cline(point1, point2)

    #simulate
    #set_graph_to_data_sample(0)
    #add_circle_trace(["18", "20"], 4)

    view.invalidate
    reset
  end

  def update(view, x, y)
    @mouse_input.update_positions(
        view, x, y, point_on_plane_from_camera_normal: @start_position || nil
    )

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
    view.line_stipple = ""
    view.line_width = 7
    view.drawing_color = 'black'
    view.draw_lines(@start_position, @end_position)
  end

  private

  # TODO replace with dynamically retrieved hinge information
  def get_mock_hinge_information
    node_a = Graph.instance.nodes[5]
    node_b = Graph.instance.nodes[7]
    edge = Graph.instance.create_edge(node_a, node_b)
    { :hinge_axis => edge.direction, :hinge_center => edge.mid_point }
  end
end

