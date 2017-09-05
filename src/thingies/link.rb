require 'src/thingies/link_entities/elongation.rb'
require 'src/thingies/link_entities/bottle_link.rb'
require 'src/thingies/link_entities/line.rb'
require 'src/simulation/simulation.rb'
require 'src/thingies/physics_thingy.rb'


class Link < PhysicsThingy
  attr_accessor :first_joint, :second_joint
  attr_reader :body, :first_elongation_length, :second_elongation_length

  def initialize(first_node, second_node, model_name, id: nil)
    super(id)

    @position = first_node.position
    @second_position = second_node.position

    @first_joint = ThingyFixedJoint.new(first_node)
    @second_joint = ThingyFixedJoint.new(second_node)

    @model = ModelStorage.instance.models[model_name]
    @first_elongation_length = nil
    @second_elongation_length = nil
    create_sub_thingies
  end

  def update_positions(first_position, second_position)
    @position = first_position
    @second_position = second_position
    delete_sub_thingies
    create_sub_thingies
  end

  def length
    @position.distance(@second_position)
  end

  def mid_point
    Geom::Point3d.linear_combination(0.5, @position, 0.5, @second_position)
  end

  #
  # Physics methods
  #

  def joint_position
    mid_point
  end

  def create_body(world)
    e1, bottles, _, e2 = @sub_thingies
    @body = Simulation.create_body(world, bottles.entity)
    ext_1_body = Simulation.create_body(world, e1.entity)
    ext_2_body = Simulation.create_body(world, e2.entity)

    @body.mass = Simulation::LINK_MASS
    @body.collidable = false
    [ext_1_body, ext_2_body].each do |body|
      body.mass = Simulation::ELONGATION_MASS
      body.collidable = false
    end

    joint_to(world, MSPhysics::Fixed, ext_1_body, Geometry::Z_AXIS, solver_model: 1)
    joint_to(world, MSPhysics::Fixed, ext_2_body, Geometry::Z_AXIS, solver_model: 1)
    @body
  end

  def create_joints(world)
    [@first_joint, @second_joint].each do |joint|
      joint.create(world, @body)
    end
  end

  def create_ball_joints(world, first_node, second_node)
    first_direction = mid_point.vector_to(first_node.position)
    second_direction = mid_point.vector_to(second_node.position)

    first_ball_joint = ThingyBallJoint.new(first_node, first_direction)
    second_ball_joint = ThingyBallJoint.new(second_node, second_direction)

    [first_ball_joint, second_ball_joint].each do |joint|
      joint.create(world, @body)
    end
  end

  def reset_physics
    super
    [@first_joint, @second_joint].each do |joint|
      joint.joint = nil
    end
  end

  #
  # Subthingy methods
  #

  def bottle_link
    @sub_thingies.find { |thingy| thingy.is_a?(BottleLink) }
  end

  def create_sub_thingies
    @first_elongation_length = @second_elongation_length = Configuration::MINIMUM_ELONGATION

    model_length = length - @first_elongation_length - @second_elongation_length
    shortest_model = @model.longest_model_shorter_than(model_length)

    @first_elongation_length = @second_elongation_length = (length - shortest_model.length) / 2

    direction = @position.vector_to(@second_position)

    first_elongation = Elongation.new(@position,
                                      direction,
                                      @first_elongation_length)

    second_elongation = Elongation.new(@second_position,
                                       direction.reverse,
                                       @second_elongation_length)

    link_position = @position.offset(first_elongation.direction)

    add(first_elongation,
        BottleLink.new(link_position, direction, shortest_model),
        Line.new(@position, @second_position),
        second_elongation)
  end

  def change_color(color)
    bottle_link.model.definition.entities.each do |ent|
      if ent.material != color
        ent.material = color
        ent.material.alpha = 0.3
      end
    end
  end
end
