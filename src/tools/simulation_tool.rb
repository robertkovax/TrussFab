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
    @simulation.chart_dialog
    @simulation.open_sensor_dialog
    Sketchup.active_model.active_view.animation = @simulation
  end

  def deactivate(view)
    @simulation.reset(view)
    @simulation.close_piston_dialog
    @simulation.close_chart
    @simulation.close_sensor_dialog
    @simulation = nil
    super
  end

  def onLButtonDown(_flags, x, y, view)
  end

  def onMouseMove(_flags, x, y, view)
  end

  def draw(view)
  end
end

class BallJointSimulationTool < SimulationTool
  def create_simulation
    BallJointSimulation.new
  end
end
