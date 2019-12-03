require 'src/system_simulation/modelica_simulation.rb'
require 'src/system_simulation/modellica_export.rb'

class SpringSimulationTool < Tool
  def initialize(ui)
    super(ui)
    @mouse_input = MouseInput.new(snap_to_edges: true, snap_to_nodes: true)
  end

  def onLButtonDown(_flags, x, y, view)
    @mouse_input.update_positions(view, x, y)
    obj = @mouse_input.snapped_object
    if !obj.nil? && obj.is_a?(Edge) && obj.link_type == 'spring'
      # TODO adjust paths
      ModellicaExport.export("src/system_simulation/test.om", obj.first_node)
      ModelicaSimulation.run_simulation
    end
  end

  def onMouseMove(_flags, x, y, view)
    @mouse_input.update_positions(view, x, y)
  end
end
