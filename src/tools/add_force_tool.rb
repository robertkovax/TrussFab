class AddForceTool < Tool
  GRAVITY = -9.800000190734863
  WEIGHT = 20 #in kg

  def initialize(ui = nil)
    super
    @mouse_input = MouseInput.new(snap_to_nodes: true, snap_to_surfaces: true)
  end

  def onLButtonDown(_flags, x, y, view)
    @mouse_input.update_positions(view, x, y)
    snapped_object = @mouse_input.snapped_object
    case snapped_object
    when Node then addForceToNode(snapped_object)
    when Triangle then addForceToSurface(snapped_object)
    end
  end

  def onMouseMove(_flags, x, y, view)
    @mouse_input.update_positions(view, x, y)
  end

  def addForceToNode(node)
    node.thingy.add_force(Geom::Vector3d.new(0, 0, WEIGHT * GRAVITY)) #in N
    node.thingy.add_force_arrow
  end

  def addForceToSurface(surface)
    addForceToNode(surface.first_node)
    addForceToNode(surface.second_node)
    addForceToNode(surface.third_node)
  end
end
