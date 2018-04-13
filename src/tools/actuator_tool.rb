require 'src/tools/physics_link_tool.rb'

class ActuatorTool < PhysicsLinkTool
  def initialize(ui)
    super(ui, 'actuator')
  end

  def onLButtonDown(_flags, x, y, view)
    edge = super(_flags, x, y, view)
    @ui.animation_pane.add_piston(edge.id) unless edge.nil?
  end
end
