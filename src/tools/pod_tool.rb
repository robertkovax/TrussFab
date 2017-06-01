class PodTool < Tool
  def initialize(ui = nil)
    super
    @mouse_input = MouseInput.new(snap_to_nodes: true)
  end

  def onLButtonDown(_flags, x, y, view)
    @mouse_input.update_positions(view, x, y)
    snapped_node = @mouse_input.snapped_graph_object
    return if snapped_node.nil?
    snapped_node.add_pod
  end

  def onMouseMove(_flags, x, y, view)
    @mouse_input.update_positions(view, x, y)
  end
end