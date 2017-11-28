require 'src/thingies/link.rb'
require 'src/thingies/link_entities/cylinder.rb'
require 'src/simulation/simulation.rb'
require 'src/simulation/joints'

class ActuatorLink < Link

  attr_reader :piston, :first_cylinder_body, :second_cylinder_body, :dampening, :rate, :min, :max

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

    @dampening = 0.1
    @rate = 1.0
    @min = -0.2
    @max = 0.2

    persist_entity
  end

  #
  # Setter
  #

  def set_dampening(value)
    @dampening = value
  end

  def set_rate(value)
    @rate = value
  end

  def set_min(value)
    @min = value
  end

  def set_max(value)
    @max = value
  end

  #
  # Physics methods
  #

  def create_body(world)
    @first_cylinder_body = @first_cylinder.create_body(world)
    @second_cylinder_body = @second_cylinder.create_body(world)

    direction_up = @position.vector_to(@second_position)
    piston_matrix = Geom::Transformation.new(@position, direction_up)
    @piston = Simulation.create_piston(world,
                                       @first_cylinder_body,
                                       @second_cylinder_body,
                                       piston_matrix,
                                       @dampening,
                                       @rate,
                                       @min,
                                       @max)

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

  def update_piston
    return if @piston.nil?
    @piston.rate = @rate
    @piston.reduction_ratio = @dampening
    @piston.min = @min
    @piston.max = @max
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

    @first_cylinder = Cylinder.new(cylinder_start, direction_up, self, @model.outer_cylinder)
    @second_cylinder = Cylinder.new(cylinder_end, direction_down, self, @model.inner_cylinder)

    add(@first_cylinder, @second_cylinder)
  end
end
