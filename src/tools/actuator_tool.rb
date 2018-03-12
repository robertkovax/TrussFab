require 'src/tools/physics_link_tool.rb'

class ActuatorTool < PhysicsLinkTool
  def initialize(ui)
    super(ui, 'actuator')
  end
end
