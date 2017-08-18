require 'src/tools/tool'
require 'src/algorithms/rigidity_tester'

class RigidityTestTool < Tool
  def initialize(ui)
    super(ui)
    @mouse_input = MouseInput.new(snap_to_nodes: true, snap_to_edges: true, snap_to_surfaces: true)
  end

  def onMouseMove(_flags, x, y, view)
    @mouse_input.update_positions(view, x, y)
  end

  def onLButtonDown(_flags, x, y, view)
    @mouse_input.update_positions(view, x, y)
    snapped_object = @mouse_input.snapped_object
    return if snapped_object.nil?
    edges = snapped_object.connected_component
    if RigidityTester.rigid?(edges)
      UI.messagebox('Selected structure is rigid.')
    else
      UI.messagebox('Selected structure is not rigid')
    end
  end
end