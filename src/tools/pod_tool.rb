class PodTool < Tool
  def initialize(ui = nil)
    super
    @mouse_input = MouseInput.new(snap_to_nodes: true, snap_to_surfaces: true)
  end

  def onLButtonDown(_flags, x, y, view)
    @mouse_input.update_positions(view, x, y)
    snapped_object = @mouse_input.snapped_object
    case snapped_object
      when Node then snapped_object.add_pod(Geometry::Z_AXIS.reverse)
      when Triangle then snapped_object.add_pods
    end
  end

  def onMouseMove(_flags, x, y, view)
    @mouse_input.update_positions(view, x, y)
  end
end