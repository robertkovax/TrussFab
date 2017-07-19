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
  def initialize(node)
    super(node)
  end

  def create(_world, other_body)
    @node.thingy.body.attach(other_body)
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

class ThingyBallJoint < ThingyJoint
  def initialize(node, direction)
    super(node)
    @direction = direction
    @joint_class = MSPhysics::BallAndSocket
  end

  def pin_direction
    @direction
  end
end