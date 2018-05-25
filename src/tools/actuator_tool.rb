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
    else
      @edge = if obj.is_a?(Edge)
                change_link_to_physics_link(view, obj)
              else
                create_new_physics_link(view, x, y)
              end
    end
  end

  COLORS = [
    '#e6194b', '#3cb44b', '#ffe119', '#0082c8', '#f58231', '#911eb4', '#46f0f0',
    '#f032e6', '#d2f53c', '#fabebe', '#008080', '#e6beff', '#aa6e28', '#fffac8',
    '#800000', '#aaffc3', '#808000', '#ffd8b1', '#000080', '#808080', '#000000'
  ].freeze

  def change_piston_group(edge)
    max_group = Graph.instance.edges.count do |e|
      e[1].thingy.is_a?(ActuatorLink)
    end - 1
    if edge.piston_group < max_group
      edge.piston_group += 1
    else
      edge.piston_group = 0
    end
    edge.thingy.material = COLORS[edge.piston_group]
    @ui.animation_pane.add_piston(edge.piston_group)
  end
end
