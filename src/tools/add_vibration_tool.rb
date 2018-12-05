# makes a clicked element vibrate
class AddVibrationTool < Tool
  def initialize(_ui = nil)
    super
    @mouse_input = MouseInput.new(snap_to_nodes: true, snap_to_surfaces: true)
  end

  def onLButtonDown(_flags, x, y, view)
    @mouse_input.update_positions(view, x, y)
    snapped_object = @mouse_input.snapped_object
    case snapped_object
    when Node then add_vibration_to_node(snapped_object)
    when Triangle then add_vibration_to_surface(snapped_object)
    end
  end

  def onMouseMove(_flags, x, y, view)
    @mouse_input.update_positions(view, x, y)
  end

  def add_vibration_to_node(node)
    node.hub.add_vibration
  end

  def add_vibration_to_surface(surface)
    add_vibration_to_node(surface.first_node)
    add_vibration_to_node(surface.second_node)
    add_vibration_to_node(surface.third_node)
  end
end
