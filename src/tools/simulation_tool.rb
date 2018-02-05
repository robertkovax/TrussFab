require 'src/tools/tool.rb'
require 'src/utility/mouse_input.rb'
require 'src/simulation/simulation.rb'

class SimulationTool < Tool
  def initialize(ui)
    super
  end

  def activate
    @simulation = Simulation.new
    @simulation.setup
    @simulation.piston_dialog
    @simulation.chart_dialog
    @simulation.open_sensor_dialog
    Sketchup.active_model.active_view.animation = @simulation
    @simulation.start
  end

  def deactivate(view)
    view.animation = nil
    @simulation.reset
    @simulation.close_piston_dialog
    @simulation.close_chart
    @simulation.close_sensor_dialog
    @simulation = nil
    super
    view.invalidate
  end

  def onLButtonDown(_flags, x, y, view)
  end

  def onMouseMove(_flags, x, y, view)
  end

  def draw(view)
  end
end
