class ThingyJoint
  def initialize(node, edge)
    @node = node
    @edge = edge
    @joint_class = MSPhysics::Fixed
    @joint = nil
  end

  def pin_direction
    @node.vector_to(@edge.other_node(@node))
  end

  def create(world, other_body)
    @joint = @node.thingy.joint_to(world, @joint_class, other_body, pin_direction)
  end

end

class ThingyHinge < ThingyJoint

  def initialize(node, edge, rotation_edge)
    super(node, edge)
    @joint_class = MSPhysics::Hinge
    @rotation_edge = rotation_edge
  end

  def pin_direction
    @rotation_edge.direction
  end
end