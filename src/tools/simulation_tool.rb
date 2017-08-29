require 'src/tools/tool.rb'
require 'src/utility/mouse_input.rb'
require 'src/simulation/simulation.rb'
require 'src/simulation/ball_joint_simulation'

class SimulationTool < Tool
  def initialize(ui)
    super
  end

  def create_simulation
    Simulation.new
  end

  def activate
    @simulation = create_simulation
    @simulation.setup
    @simulation.piston_dialog
    @simulation.add_ground
    @simulation.start
    Sketchup.active_model.active_view.animation = @simulation
  end

  def deactivate(view)
    Sketchup.active_model.active_view.animation = nil
    @simulation = nil
    super
  end

  def onLButtonDown(_flags, x, y, view)
  end

  def onMouseMove(_flags, x, y, view)
  end

  def draw(view)
    @simulation.show_forces(view)
  end
end

class BallJointSimulationTool < SimulationTool
  def create_simulation
    BallJointSimulation.new
  end
end
