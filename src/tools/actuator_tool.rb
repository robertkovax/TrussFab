require 'src/tools/physics_link_tool.rb'

# Tool that places an actuator between two hubs or turns an existing edge into
# an actuator
class ActuatorTool < PhysicsLinkTool
  def initialize(ui)
    super(ui, 'actuator')
  end

  def onLButtonDown(flags, x, y, view)
    edge = super(flags, x, y, view)
    @ui.animation_pane.add_piston(edge.id) unless edge.nil?
  end
end
