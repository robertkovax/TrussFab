require 'src/tools/tool.rb'
require 'src/utility/mouse_input.rb'
require 'src/simulation/simulation.rb'
require 'src/simulation/ball_joint_simulation'

class SimulationTool < Tool
  def initialize(ui)
    super
    @simulation = BallJointSimulation.new
  end

  def activate
    @simulation.setup
    @simulation.start
    @simulation.piston_dialog
    Sketchup.active_model.active_view.animation = @simulation
  end

  def deactivate(view)
    Sketchup.active_model.active_view.animation = nil
    super
  end

  def onLButtonDown(_flags, x, y, view)
  end

  def onMouseMove(_flags, x, y, view)
  end

  def draw(view)
    # @simulation.show_forces(view)
  end

  private

  def reset
  end
end
