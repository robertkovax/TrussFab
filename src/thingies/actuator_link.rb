require 'src/thingies/link.rb'
require 'src/thingies/link_entities/cylinder.rb'
require 'src/simulation/simulation.rb'
require 'src/simulation/joints'

class ActuatorLink < Link

  attr_reader :piston, :first_cylinder_body, :second_cylinder_body

  def initialize(first_node, second_node, id: nil)
    @first_cylinder = nil
    @second_cylinder = nil

    @first_cylinder_body = nil
    @second_cylinder_body = nil

    @piston = nil
    super(first_node, second_node, 'actuator', id: id)

    @first_joint = ThingyBallJoint.new(first_node,
                                       mid_point.vector_to(@position))
    @second_joint = ThingyBallJoint.new(second_node,
                                        mid_point.vector_to(@second_position))
  end

  #
  # Physics methods
  #

  def create_body(world)
    @first_cylinder_body = @first_cylinder.create_body(world)
    @second_cylinder_body = @second_cylinder.create_body(world)

    ext_1_body = Simulation.create_body(world, @first_elongation.entity)
    ext_2_body = Simulation.create_body(world, @second_elongation.entity)

    direction_up = @position.vector_to(@second_position)
    piston_matrix = Geom::Transformation.new(@position, direction_up)
    @piston = Simulation.create_piston(world,
                                       @first_cylinder_body,
                                       @second_cylinder_body,
                                       piston_matrix)

    [ext_1_body, ext_2_body].each do |body|
      body.mass = Simulation::ELONGATION_MASS
      body.collidable = false
    end

    joint_from_to(world, MSPhysics::Fixed, @first_cylinder_body, ext_1_body, Geometry::Z_AXIS)
    joint_from_to(world, MSPhysics::Fixed, @second_cylinder_body, ext_2_body, Geometry::Z_AXIS)

    [@first_cylinder_body, @second_cylinder_body]
  end

  def create_joints(world)
    @first_joint.create(world, @first_cylinder.body)
    @second_joint.create(world, @second_cylinder.body)
  end

  def create_ball_joints(world, first_node, second_node)
    first_direction = mid_point.vector_to(first_node.position)
    second_direction = mid_point.vector_to(second_node.position)

    first_ball_joint = ThingyBallJoint.new(first_node, first_direction)
    second_ball_joint = ThingyBallJoint.new(second_node, second_direction)

    first_ball_joint.create(world, @first_cylinder.body)
    second_ball_joint.create(world, @second_cylinder.body)
  end

  def reset_physics
    super
    @piston = nil
    @first_cylinder_body = nil
    @second_cylinder_body = nil
    [@first_cylinder, @second_cylinder].each do |cylinder|
      cylinder.body = nil
    end
  end

  #
  # Subthingy methods
  #

  def create_sub_thingies
    @first_elongation_length = @second_elongation_length = Configuration::MINIMUM_ELONGATION

    direction_up = @position.vector_to(@second_position)
    direction_down = @second_position.vector_to(@position)

    offset_up = direction_up.clone
    offset_down = direction_down.clone

    offset_up.length = @first_elongation_length
    offset_down.length = @second_elongation_length

    cylinder_start = @position.offset(offset_up)
    cylinder_end = @second_position.offset(offset_down)

    @first_elongation = Elongation.new(@position,
                                      direction_up,
                                      @first_elongation_length)

    @second_elongation = Elongation.new(@second_position,
                                       direction_down,
                                       @second_elongation_length)

    @first_cylinder = Cylinder.new(cylinder_start, direction_up, @model.outer_cylinder)
    @second_cylinder = Cylinder.new(cylinder_end, direction_down, @model.inner_cylinder)

    add(@first_elongation, @first_cylinder, @second_cylinder, @second_elongation)
  end
end