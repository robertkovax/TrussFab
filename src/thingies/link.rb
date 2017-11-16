require 'src/thingies/link_entities/elongation.rb'
require 'src/thingies/link_entities/bottle_link.rb'
require 'src/thingies/link_entities/line.rb'
require 'src/simulation/simulation.rb'
require 'src/thingies/physics_thingy.rb'


class Link < PhysicsThingy
  attr_accessor :first_joint, :second_joint
  attr_reader :body, :first_elongation_length, :second_elongation_length,
    :position, :second_position, :loc_up_vec

  def initialize(first_node, second_node, model_name, id: nil)
    super(id)

    @position = first_node.position
    @second_position = second_node.position
    # the vector pointing along the length of the bottle
    @loc_up_vec = Geom::Vector3d.new(0, 0, -1)

    @mass = 0

    @first_node = first_node
    @second_node = second_node

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

  def joint_position
    mid_point
  end

  #
  # Physics methods
  #

  def create_body(world)
    e1, bottles, _, e2 = @sub_thingies
    @body = Simulation.create_body(world, bottles.entity, collision_type: :convex_hull)
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
    update_up_vector
    @body
  end

  def create_bottle_joints(world, joint_type = ThingyFixedJoint)
    adjacent_edges = []
    @first_node.incidents.map{|edge| adjacent_edges << edge unless edge.thingy == self}
    @second_node.incidents.map{|edge| adjacent_edges << edge unless edge.thingy == self}
    # adjacent_edges << @first_joint
    # adjacent_edges << @second_joint
    adjacent_edges.each do |edge|
      unless edge.nil?
        if joint_type == ThingyBallJoint
          joint = joint_type.new(edge, mid_point.vector_to(edge.position)).create(world, @body)
          joint.twist_limits_enabled = true
          joint.max_twist_angle = 3
        else
          joint_type.new(edge).create(world, @body)
        end
      end
    end
  end

  def create_joints(world)
    # create_bottle_joints(world, ThingyBallJoint)
    [@first_joint, @second_joint].each do |joint|
      joint.create(world, @body)
    end

    # Simulation.joint_between(world, MSPhysics::Fixed, ext_1_body, @first_node.thingy.body, Geometry::Z_AXIS)
    # Simulation.joint_between(world, MSPhysics::Fixed, ext_2_body, @second_node.thingy.body, Geometry::Z_AXIS)
  end

  def create_ball_joints(world, first_node, second_node)
    create_bottle_joints(world, ThingyBallJoint)

    first_direction = mid_point.vector_to(first_node.position)
    second_direction = mid_point.vector_to(second_node.position)

    @first_joint = ThingyBallJoint.new(first_node, first_direction)
    @second_joint = ThingyBallJoint.new(second_node, second_direction)

    [@first_joint, @second_joint].each do |joint|
      joint.create(world, @body)
    end
  end

  def add_mass(mass)
    @mass += mass
  end

  def reset_physics
    super
    [@first_joint, @second_joint].each do |joint|
      joint.joint = nil
    end
  end

  def update_force
    @body.set_force(0, 0, -@mass)
  end

  def update_up_vector
    body_tra = @body.get_matrix
    glob_up_vec = @loc_up_vec.transform(body_tra)
    if (second_position - position).dot(glob_up_vec) > 0.0
      @loc_up_vec.reverse!
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
end
