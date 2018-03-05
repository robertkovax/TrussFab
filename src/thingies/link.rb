require 'src/thingies/link_entities/elongation.rb'
require 'src/thingies/link_entities/bottle_link.rb'
require 'src/thingies/link_entities/line.rb'
require 'src/simulation/simulation.rb'
require 'src/thingies/physics_thingy.rb'


class Link < PhysicsThingy
  attr_accessor :joint
  attr_reader :first_elongation_length, :second_elongation_length,
    :position, :second_position, :loc_up_vec, :first_node, :second_node, :sensor_symbol

  def initialize(first_node, second_node, model_name, id: nil)
    super(id)

    @position = first_node.position
    @second_position = second_node.position
    # the vector pointing along the length of the bottle
    @loc_up_vec = Geom::Vector3d.new(0, 0, -1)

    @first_node = first_node
    @second_node = second_node

    @model = ModelStorage.instance.models[model_name]
    if @model.nil?
      raise "#{model_name} does not have a model yet"
    end
    @first_elongation_length = nil
    @second_elongation_length = nil

    @first_elongation = nil
    @second_elongation = nil

    @sensor_symbol = nil

    create_sub_thingies
  end

  def delete
    @sensor_symbol.erase! unless @sensor_symbol.nil?
    super
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

  def mid_point
    p1 = @position
    p2 = @second_position
    Geom::Point3d.linear_combination(0.5, p1, 0.5, p2)
  end

  def add_sensor_symbol
    point = mid_point
    model = ModelStorage.instance.models['sensor']
    # s**t ton of transformation to align the image exactly with the bottle direction, which is
    # not really needed anymore, because the object is now 3D. Will leave it here anyways, because
    # I don't want to throw away all this work :(
    transform = Geom::Transformation.new(point)
    @sensor_symbol = Sketchup.active_model.active_entities.add_instance(model.definition, transform)
    image_normal = Geom::Vector3d.new(0, 0, 1)
    floor_normal = Geom::Vector3d.new(0, 0, 1)
    link_dir = @position.vector_to(@second_position)
    second_angle = link_dir.angle_between(floor_normal)
    rotation = Geom::Transformation.rotation(point, link_dir, link_dir.angle_between(link_dir.cross(floor_normal)))
    @sensor_symbol.transform!(rotation)
    image_normal.transform!(rotation)
    rotation2 = Geom::Transformation.rotation(point, image_normal.cross(link_dir), second_angle)
    @sensor_symbol.transform!(rotation2)
    @sensor_symbol.transform!(Geom::Transformation.scaling(point, 0.2))
  end

  def toggle_sensor_state
    if @is_sensor
      @is_sensor = false
      @sensor_symbol.erase!
      @sensor_symbol = nil
    else
      @is_sensor = true
      add_sensor_symbol
    end
  end

  def is_sensor?
    @is_sensor
  end

  def move_sensor_symbol(position)
    unless @sensor_symbol.nil?
      old_pos = @sensor_symbol.transformation.origin
      movement_vec = old_pos.vector_to(position)
      @sensor_symbol.transform!(movement_vec)
    end
  end

  def reset_sensor_symbol_position
    move_sensor_symbol(mid_point)
  end

  #
  # Physics methods
  #

  def update_link_transformations
    pt1 = @first_node.thingy.entity.bounds.center
    pt2 = @second_node.thingy.entity.bounds.center
    pt3 = Geom::Point3d.linear_combination(0.5, pt1, 0.5, pt2)
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
    t3 = Geom::Transformation.new(pt2 - Geometry.scale_vector(dir, elong2.length), dir.reverse)

    elong1.entity.move!(t1)
    elong2.entity.move!(t2)
    bottle.entity.move!(t3)

    move_sensor_symbol(pt3)
  end

  def create_joints(world, first_node, second_node)
    # Associated nodes are to be connected with one joint:
    #   Node A connected to Node B by PointToPoint constraint.
    # The link object in between will not be part of physics simulation.
    bd1 = first_node.thingy.body
    bd2 = second_node.thingy.body
    pt1 = bd1.group.bounds.center
    pt2 = bd2.group.bounds.center
    @joint = TrussFab::PointToPoint.new(world, bd1, bd2, pt1, pt2, nil)
    @joint.solver_model = Configuration::JOINT_SOLVER_MODEL
    @joint.stiffness = Configuration::JOINT_STIFFNESS
    @joint.breaking_force = Configuration::JOINT_BREAKING_FORCE
  end

  def reset_physics
    super
    @joint = nil
  end

  #
  # Subthingy methods
  #

  def shorten_elongation(is_first_joint)
    if is_first_joint
      @first_elongation.shorten(@first_elongation.direction)
    else
      @second_elongation.shorten(@second_elongation.direction)
    end
  end

  def bottle_link
    @sub_thingies.find { |thingy| thingy.is_a?(BottleLink) }
  end

  def create_sub_thingies
    @first_elongation_length =
      @second_elongation_length =
      Configuration::MINIMUM_ELONGATION

    length = @first_node.position.distance(@second_node.position)

    model_length = length - @first_elongation_length - @second_elongation_length
    shortest_model = @model.longest_model_shorter_than(model_length)

    @first_elongation_length =
      @second_elongation_length =
      (length - shortest_model.length) / 2

    direction = @position.vector_to(@second_position)

    @first_elongation = Elongation.new(@position,
                                       direction,
                                       @first_elongation_length)

    @second_elongation = Elongation.new(@second_position,
                                        direction.reverse,
                                        @second_elongation_length)

    link_position = @position.offset(@first_elongation.direction)

    add(@first_elongation,
        BottleLink.new(link_position, direction, shortest_model),
        Line.new(@position, @second_position, LINK_LINE),
        @second_elongation)
  end
end
