# Adds a weight of 5 kg/click/node. The weight is not directed, i.e. it is
# always pointing against gravity and has inertia
class AddWeightTool < Tool
  WEIGHT = 5 # in kg

  def initialize(_ui = nil)
    super
    @mouse_input = MouseInput.new(snap_to_nodes: true, snap_to_surfaces: true)
  end

  def onLButtonDown(_flags, x, y, view)
    @mouse_input.update_positions(view, x, y)
    snapped_object = @mouse_input.snapped_object
    case snapped_object
    when Node then add_weight_to_node(snapped_object)
    when Triangle then add_weight_to_surface(snapped_object)
    end
  end

  def onMouseMove(_flags, x, y, view)
    @mouse_input.update_positions(view, x, y)
  end

  def add_weight_to_node(node)
    node.hub.add_weight(WEIGHT) # in kg
  end

  def add_weight_to_surface(surface)
    add_weight_to_node(surface.first_node)
    add_weight_to_node(surface.second_node)
    add_weight_to_node(surface.third_node)
  end
end
