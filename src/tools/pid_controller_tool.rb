require 'src/tools/physics_link_tool.rb'

# Tool that places a pid controlled actuator, controlling the force with the controller
class PIDControllerTool < PhysicsLinkTool
  def initialize(ui)
    super(ui, 'pid_controller')
  end
end
