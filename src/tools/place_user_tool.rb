# Specifies for dynamic structures where (and in which pose) the user will be placed.
class PlaceUserTool < Tool

  def initialize(_ui = nil)
    super
    @mouse_input = MouseInput.new(snap_to_nodes: true, snap_to_surfaces: true)
  end

  def onLButtonDown(_flags, x, y, view)
    @mouse_input.update_positions(view, x, y)
    snapped_object = @mouse_input.snapped_object
    if snapped_object.is_a?(Node)
      snapped_object.hub.toggle_attached_user
    end
  end

  def onMouseMove(_flags, x, y, view)
    @mouse_input.update_positions(view, x, y)
  end

  def add_weight_to_node(node)

  end

end
