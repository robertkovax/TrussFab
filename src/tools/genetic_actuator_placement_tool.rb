require 'src/tools/tool'
require 'src/database/graph.rb'

class GeneticActuatorPlacementTool < Tool
  def initialize(ui)
    super(ui)
    @mouse_input = MouseInput.new(snap_to_nodes: true)
    @move_mouse_input = nil

    @node = nil
    @start_position = nil
    @desired_position = nil
    @moving = false
  end

  def create_actuator(edge)
    Sketchup.active_model.start_operation('toggle edge to actuator', true)
    edge.link_type = 'actuator'
    Sketchup.active_model.commit_operation
  end

  def reset_actuator_type(edge, previous_link_type)
    Sketchup.active_model.start_operation('toggle actuator to edge', true)
    edge.link_type = previous_link_type
    Sketchup.active_model.commit_operation
  end

  def activate
  end

  def deactivate(view)
    super(view)
    reset
  end

  def reset
    @node = nil
    @start_position = nil
    @desired_position = nil
    @moving = false
  end

  def test_pistons
    model = Sketchup.active_model
    closest_distance = Float::INFINITY
    best_piston = nil
    Graph.instance.edges.each_value do |edge|
      next if edge.fixed?
      previous_link_type = edge.link_type
      create_actuator(edge)
      simulation = Simulation.new
      simulation.setup
      simulation.schedule_piston_for_testing(edge)
      simulation.start
      model.start_operation('simulate a piston', true)
      distance = simulation.test_pistons_for(2, @node, @desired_position)
      model.commit_operation
      if distance < closest_distance
        closest_distance = distance
        best_piston = edge
      end
      if distance < 50
        return
      end
      model.start_operation('reset simulation', true)
      simulation.reset
      simulation = nil
      model.commit_operation
      reset_actuator_type(edge, previous_link_type)
    end
    create_actuator(best_piston) unless best_piston.nil?
  end

  def update(view, x, y)
    @mouse_input.update_positions(
      view, x, y, point_on_plane_from_camera_normal: @start_position || nil
    )

    return unless @moving && (@mouse_input.position != @desired_position)
    @desired_position = @mouse_input.position
    view.invalidate
  end

  def onMouseMove(_flags, x, y, view)
    update(view, x, y)
  end

  def onLButtonDown(_flags, x, y, view)
    update(view, x, y)
    node = @mouse_input.snapped_object
    return if node.nil?
    @moving = true
    @node = node
    @start_position = @desired_position = @mouse_input.position
  end

  def onLButtonUp(_flags, x, y, view)
    update(view, x, y)
    return unless @moving
    @moving = false
    @desired_position = @mouse_input.position
    # test_pistons

    view.invalidate
    reset
  end

  def draw(view)
    return if @start_position.nil? || @desired_position.nil? || !@moving
    view.line_stipple = '_'
    view.draw_lines(@start_position, @desired_position)
  end
end
