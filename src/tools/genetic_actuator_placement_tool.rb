require 'src/tools/tool'
require 'src/database/graph.rb'

# Automatically tries to find the best place for an actuator by exchanging all
# edges with actuators and trying them out, checking which actuator brings the
# selected node closest to the selected position
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
    edge.link_type = 'actuator'
  end

  def reset_actuator_type(edge, previous_link_type)
    edge.link_type = previous_link_type
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
    puts("test_pistons")
    model = Sketchup.active_model
    closest_distance = Float::INFINITY
    best_piston = nil
    simulation = Simulation.new
    model.start_operation('test_pistons', true)
    Graph.instance.edges.each_value do |edge|
      next if edge.fixed?
      previous_link_type = edge.link_type
      create_actuator(edge)
      simulation.setup
      simulation.schedule_piston_for_testing(edge, 10)
      simulation.start
      edge.link.joint.rate = 10
      distance = simulation.test_pistons_for(1, @node, @desired_position)
      if distance < closest_distance
        closest_distance = distance
        best_piston = edge
      end
      simulation.reset
      simulation.unschedule_piston_for_testing(edge, 10)
      break if distance < 10
      reset_actuator_type(edge, previous_link_type)
    end
    return if best_piston.nil?
    create_actuator(best_piston)
    piston_group = IdManager.instance.maximum_piston_group + 1
    best_piston.link.piston_group = piston_group
    @ui.animation_pane.add_piston(piston_group)
    @ui.animation_pane.sync_hidden_status(Graph.instance.actuator_groups)
    model.commit_operation
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
    test_pistons

    view.invalidate
    reset
  end

  def draw(view)
    return if @start_position.nil? || @desired_position.nil? || !@moving
    view.line_stipple = '_'
    view.draw_lines(@start_position, @desired_position)
  end
end
