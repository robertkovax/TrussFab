require 'src/tools/tool.rb'
require 'src/utility/mouse_input.rb'
require 'src/simulation/simulation.rb'
require 'src/algorithms/rigidity_tester.rb'
require 'src/simulation/thingy_rotation.rb'

class ActuatorTool < Tool

  MIN_ANGLE_DEVIATION = 0.05

  def initialize(ui)
    super
    @mouse_input = MouseInput.new(snap_to_edges: true, snap_to_nodes: true)
  end

  #
  # Sketchup Tool methods
  #

  def deactivate(view)
    super
  end

  def onLButtonDown(_flags, x, y, view)
    @mouse_input.update_positions(view, x, y)
    obj = @mouse_input.snapped_object
    return if obj.nil?
    if obj.is_a?(Edge)
      change_link_to_actuator(view, obj)
    else
      create_new_actuator(view, x, y)
    end
  end

  def onMouseMove(_flags, x, y, view)
    @mouse_input.update_positions(view, x, y)
  end

  #
  # Tool logic
  #

  def change_link_to_actuator(view, edge)
    Sketchup.active_model.start_operation('toggle edge to actuator', true)
    edge.link_type = 'actuator'
    view.invalidate
    Sketchup.active_model.commit_operation
  end

  def create_new_actuator(view, x, y)
    if @first_position.nil?
      @first_position = @mouse_input.update_positions(view, x, y)
    else
      second_position = @mouse_input.update_positions(view, x, y, point_on_plane_from_camera_normal: @first_position)

      puts 'Create single actuator link'
      Sketchup.active_model.start_operation('Create actuator link', true)
      Graph.instance.create_edge_from_points(@first_position,
                                             second_position,
                                             link_type: 'actuator')
      Sketchup.active_model.commit_operation
      reset
    end
  end

  private

  def reset
    @mouse_input.soft_reset
    @first_position = nil
  end
end
