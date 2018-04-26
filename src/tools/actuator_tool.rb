require 'src/tools/physics_link_tool.rb'

# Tool that places an actuator between two hubs or turns an existing edge into
# an actuator
class ActuatorTool < PhysicsLinkTool
  def initialize(ui)
    super(ui, 'actuator')
  end

  def onLButtonDown(flags, x, y, view)
    @mouse_input.update_positions(view, x, y)
    obj = @mouse_input.snapped_object
    return if obj.nil?
    if obj.is_a?(Edge) && obj.link_type == @link_type
      change_piston_group(obj)
    else
      @edge = if obj.is_a?(Edge)
                change_link_to_physics_link(view, obj)
              else
                create_new_physics_link(view, x, y)
              end
      @ui.animation_pane.add_piston(@edge.id) unless @edge.nil?
    end
  end

  def change_piston_group(edge)
    p edge.automatic_movement_group
  end
end
