class AddWeightTool < Tool
  GRAVITY = 9.800000190734863

  def initialize(ui = nil)
    super
    @mouse_input = MouseInput.new(snap_to_nodes: true, snap_to_surfaces: true)
  end

  def onLButtonDown(_flags, x, y, view)
    @mouse_input.update_positions(view, x, y)
    snapped_object = @mouse_input.snapped_object
    case snapped_object
    when Node then addWeightToNode(snapped_object)
    when Triangle then addWeightToSurface(snapped_object)
    end
  end

  def onMouseMove(_flags, x, y, view)
    @mouse_input.update_positions(view, x, y)
  end

  def addWeightToNode(node)
    node.thingy.add_mass(20 * GRAVITY)
    node.thingy.add_force_arrow
  end

  def addWeightToSurface(surface)
    addWeightToNode(surface.first_node)
    addWeightToNode(surface.second_node)
    addWeightToNode(surface.third_node)
  end
end
