class ThingyJoint
  def initialize(node)
    @node = node
    @joint_class = nil
    @joint = nil
  end

  def pin_direction
    raise NotImplementedError
  end

  def create(world, other_body)
    @joint = @node.thingy.joint_to(world, @joint_class, other_body, pin_direction)
  end
end

class ThingyFixedJoint < ThingyJoint
  def initialize(node, edge)
    super(node)
    @edge = edge
    @joint_class = MSPhysics::Fixed
  end

  def pin_direction
    @node.vector_to(@edge.other_node(@node))
  end
end

class ThingyHinge < ThingyJoint
  def initialize(node, thingy_rotation)
    super(node)
    @rotation = thingy_rotation
    @joint_class = MSPhysics::Hinge
  end

  def pin_direction
    @rotation.vector
  end
end

class ThingyBallJoint < ThingyHinge
  def initialize(node, thingy_rotation)
    super(node, thingy_rotation)
    @joint_class = MSPhysics::BallAndSocket
  end
end