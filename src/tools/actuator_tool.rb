require 'src/tools/link_tool.rb'

# Tool that places an actuator between two hubs or turns an existing edge into
# an actuator
class ActuatorTool < LinkTool
  def initialize(ui)
    super(ui, 'actuator')
  end

  def onLButtonDown(flags, x, y, view)
    @mouse_input.update_positions(view, x, y)
    obj = @mouse_input.snapped_object
    return if obj.nil?
    if obj.is_a?(Edge) && obj.link_type == @link_type
      change_piston_group(obj)
      @ui.animation_pane.add_piston(obj.thingy.piston_group)
    else
      @edge = if obj.is_a?(Edge)
                change_link_to_physics_link(view, obj)
              else
                create_new_physics_link(view, x, y)
              end
      @edge.thingy.piston_group = IdManager.instance.maximum_piston_group
      @ui.animation_pane.add_piston(@edge.thingy.piston_group)
    end
  end

  def change_piston_group(edge)
    max_group = Graph.instance.edges.count do |e|
      e[1].thingy.is_a?(ActuatorLink)
    end - 1
    if edge.thingy.piston_group < max_group
      edge.thingy.piston_group += 1
    else
      edge.thingy.piston_group = 0
    end
  end
end
