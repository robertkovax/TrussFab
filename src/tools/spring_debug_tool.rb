require 'src/system_simulation/modelica_simulation.rb'
require 'src/system_simulation/modellica_export.rb'
require 'benchmark'
require 'src/system_simulation/simulation_runner.rb'

# Simple Debugging tool to execute commands
class SpringDebugTool < Tool
  def initialize(ui)
    super(ui)
    @mouse_input = MouseInput.new(snap_to_edges: true, snap_to_nodes: true)
    @runner = nil
  end

  def activate
    @runner = SimulationRunner.new unless @runner
  end

  def onLButtonDown(_flags, x, y, view)
    @mouse_input.update_positions(view, x, y)
    obj = @mouse_input.snapped_object
    if !obj.nil? && obj.is_a?(Edge)
      # enter commands here:

      p @runner.optimize_constant_for_constrained_angle
    end
  end

  def onMouseMove(_flags, x, y, view)
    @mouse_input.update_positions(view, x, y)
  end
end
