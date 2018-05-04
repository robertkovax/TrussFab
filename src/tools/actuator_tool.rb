require 'src/tools/link_tool.rb'

# Tool that places an actuator between two hubs or turns an existing edge into
# an actuator
class ActuatorTool < LinkTool
  def initialize(ui)
    super(ui, 'actuator')
  end

  def onLButtonDown(flags, x, y, view)
    edge = super(flags, x, y, view)
    @ui.animation_pane.add_piston(edge.id) unless edge.nil?
  end
end
