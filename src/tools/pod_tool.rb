class PodTool < Tool
  def initialize(ui = nil)
    super
    @mouse_input = MouseInput.new(snap_to_nodes: true, snap_to_surfaces: true)
  end

  def onLButtonDown(_flags, x, y, view)
    @mouse_input.update_positions(view, x, y)
    snapped_object = @mouse_input.snapped_object
    return if snapped_object.nil?
    snapped_object.add_pod(Geometry::Z_AXIS.reverse) if snapped_object.is_a?(Node)
    snapped_object.add_pods if snapped_object.is_a?(Triangle)
  end

  def onMouseMove(_flags, x, y, view)
    @mouse_input.update_positions(view, x, y)
  end
end