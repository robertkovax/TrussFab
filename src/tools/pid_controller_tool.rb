require 'src/tools/generic_physics_link_tool.rb'

# Tool that places a pid controlled actuator, controlling the force with the controller
class PIDControllerTool < GenericPhysicsLinkTool
  def initialize(ui)
    super(ui, link_type: 'pid_controller')
  end
end
