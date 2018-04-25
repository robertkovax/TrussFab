# Adds a directed force of 5 kg/click/node
class AddForceTool < Tool
  GRAVITY = -9.800000190734863
  WEIGHT = 5 # in kg

  def initialize(_ui = nil)
    super
    @mouse_input = MouseInput.new(snap_to_nodes: true, snap_to_surfaces: true)
  end

  def onLButtonDown(_flags, x, y, view)
    @mouse_input.update_positions(view, x, y)
    snapped_object = @mouse_input.snapped_object
    case snapped_object
    when Node then add_force_to_node(snapped_object)
    when Triangle then add_force_to_surface(snapped_object)
    end
  end

  def onMouseMove(_flags, x, y, view)
    @mouse_input.update_positions(view, x, y)
  end

  def add_force_to_node(node)
    node.thingy.add_force(Geom::Vector3d.new(0, 0, WEIGHT * GRAVITY)) # in N
    node.thingy.add_force_arrow
  end

  def add_force_to_surface(surface)
    add_force_to_node(surface.first_node)
    add_force_to_node(surface.second_node)
    add_force_to_node(surface.third_node)
  end
end
