require 'src/thingies/link_entities/elongation.rb'
require 'src/thingies/link_entities/bottle_link.rb'
require 'src/thingies/link_entities/line.rb'
require 'src/simulation/simulation.rb'
require 'src/thingies/physics_thingy.rb'


class Link < PhysicsThingy
  attr_accessor :joint
  attr_reader :first_elongation_length, :second_elongation_length,
    :position, :second_position, :loc_up_vec, :first_node, :second_node

  def initialize(first_node, second_node, model_name, id: nil)
    super(id)

    @position = first_node.position
    @second_position = second_node.position
    # the vector pointing along the length of the bottle
    @loc_up_vec = Geom::Vector3d.new(0, 0, -1)

    @first_node = first_node
    @second_node = second_node

    @model = ModelStorage.instance.models[model_name]
    @first_elongation_length = nil
    @second_elongation_length = nil
    create_sub_thingies
  end

  def check_if_valid
    (super && (@first_node.nil? || @first_node.thingy.check_if_valid) && (@second_node.nil? || @second_node.thingy.check_if_valid)) ? true : false
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

  def update_link_transformations
    pt1 = @first_node.thingy.entity.bounds.center
    pt2 = @second_node.thingy.entity.bounds.center
    dir = pt2 - pt1

    return if (dir.length.to_f < 1.0e-6)

    elong1 = @sub_thingies[0]
    elong2 = @sub_thingies[3]
    bottle = @sub_thingies[1]

    scale1 = Geom::Transformation.scaling(elong1.radius, elong1.radius, elong1.length)
    scale2 = Geom::Transformation.scaling(elong2.radius, elong2.radius, elong2.length)

    dir.normalize!
    t1 = Geom::Transformation.new(pt1, dir) * scale1
    t2 = Geom::Transformation.new(pt2, dir.reverse) * scale2
    t3 = Geom::Transformation.new(pt2 - AMS::Geometry.scale_vector(dir, elong2.length), dir.reverse)

    elong1.entity.move!(t1)
    elong2.entity.move!(t2)
    bottle.entity.move!(t3)
  end

  def create_joints(world, first_node, second_node)
    # Associated nodes are to be connected with one joint:
    #   Node A connected to Node B by PointToPoint constraint.
    # The link object in between will not be part of physics simulation.
    bd1 = first_node.thingy.body
    bd2 = second_node.thingy.body
    @joint = MSPhysics::PointToPoint.new(world, bd1, bd1.group.bounds.center, bd2.group.bounds.center, nil)
    @joint.connect(bd2)
    @joint.stiffness = Simulation::DEFAULT_STIFFNESS
  end

  def reset_physics
    super
    @joint = nil
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
    @first_elongation_length =
      @second_elongation_length =
      Configuration::MINIMUM_ELONGATION

    model_length = length - @first_elongation_length - @second_elongation_length
    shortest_model = @model.longest_model_shorter_than(model_length)

    @first_elongation_length =
      @second_elongation_length =
      (length - shortest_model.length) / 2

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
        Line.new(@position, @second_position, LINK_LINE),
        second_elongation)
  end
end
