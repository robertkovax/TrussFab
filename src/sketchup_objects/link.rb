require 'src/sketchup_objects/link_entities/elongation.rb'
require 'src/sketchup_objects/link_entities/bottle_link.rb'
require 'src/sketchup_objects/link_entities/pipe_link.rb'
require 'src/sketchup_objects/link_entities/line.rb'
require 'src/simulation/simulation.rb'
require 'src/sketchup_objects/physics_sketchup_object.rb'
require 'src/configuration/configuration'

# Link
class Link < PhysicsSketchupObject
  attr_accessor :joint, :model, :first_node, :second_node
  attr_reader :first_elongation_length, :second_elongation_length, :position,
              :second_position, :loc_up_vec, :sensor_symbol, :piston_group

  def initialize(first_node, second_node, edge, model_name, bottle_name: '',
                 id: nil)
    super(id)

    @position = first_node.position
    @second_position = second_node.position
    @edge = edge
    # the vector pointing along the length of the bottle
    @loc_up_vec = Geom::Vector3d.new(0, 0, -1)

    @first_node = first_node
    @second_node = second_node

    @model = nil

    @piston_group = -1

    # extract specific bottle model for bottle links
    if model_name == Configuration::STANDARD_BOTTLES
      raise 'No bottle type supplied.' if bottle_name.empty?
      @model = ModelStorage.instance.models[model_name].models[bottle_name]
    else
      @model = ModelStorage.instance.models[model_name]
    end

    raise "#{model_name} does not have a model yet" if @model.nil?

    @first_elongation_length = nil
    @second_elongation_length = nil

    @first_elongation = nil
    @second_elongation = nil

    @sensor_symbol = nil

    @elongation_ratio = 0.5

    create_children
  end

  def elongation_ratio
    @elongation_ratio
  end

  def elongation_ratio=(val)
    @elongation_ratio = val
    recreate_children
  end

  def change_elongation_length(elongation, length)
    new_first_elongation_length = @first_elongation_length
    new_second_elongation_length = @second_elongation_length

    if elongation == @first_elongation
      new_first_elongation_length = length
    elsif elongation == @second_elongation
      new_second_elongation_length = length
    else
      raise 'Logic error: elongation does not belong to link.'
    end

    old_total_length =
      @first_elongation_length + @second_elongation_length
    new_total_length =
      new_first_elongation_length + new_second_elongation_length

    @elongation_ratio = new_first_elongation_length / new_total_length

    difference = new_total_length - old_total_length

    Relaxation.new.stretch_to(@edge, self.length + difference).relax
  end

  def delete
    @sensor_symbol.erase! unless @sensor_symbol.nil?
    super
  end

  def check_if_valid
    super && (@first_node.nil? || @first_node.hub.check_if_valid) &&
      (@second_node.nil? || @second_node.hub.check_if_valid)
  end

  def update_positions(first_position, second_position)
    return if first_position == @first_position &&
      second_position == @second_position

    @position = first_position
    @second_position = second_position
    recreate_children
  end

  def length
    @position.distance(@second_position)
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
    Sketchup.active_model.start_operation('Add Sensor Symbol', true)
    point = mid_point
    model = ModelStorage.instance.models['sensor']
    # s**t ton of transformation to align the image exactly with the bottle
    # direction, which is not really needed anymore, because the object is
    # now 3D. Will leave it here anyways, because I don't want to throw away
    # all this work :(
    transform = Geom::Transformation.new(point)
    @sensor_symbol = Sketchup.active_model
                       .active_entities
                       .add_instance(model.definition, transform)
    image_normal = Geom::Vector3d.new(0, 0, 1)
    floor_normal = Geom::Vector3d.new(0, 0, 1)
    link_dir = @position.vector_to(@second_position)
    second_angle = link_dir.angle_between(floor_normal)
    rotation = Geom::Transformation
                 .rotation(point, link_dir,
                           link_dir.angle_between(link_dir.cross(floor_normal)))
    @sensor_symbol.transform!(rotation)
    image_normal.transform!(rotation)
    rotation2 = Geom::Transformation.rotation(point,
                                              image_normal.cross(link_dir),
                                              second_angle)
    @sensor_symbol.transform!(rotation2)
    @sensor_symbol.transform!(Geom::Transformation.scaling(point, 0.2))
    Sketchup.active_model.commit_operation
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

  def sensor?
    @is_sensor
  end

  def move_sensor_symbol(position)
    return if @sensor_symbol.nil?
    old_pos = @sensor_symbol.transformation.origin
    movement_vec = Geom::Transformation.translation(old_pos.vector_to(position))
    @sensor_symbol.move!(movement_vec * @sensor_symbol.transformation)
  end

  def reset_sensor_symbol_position
    move_sensor_symbol(mid_point)
  end

  #
  # Physics methods
  #

  def update_link_transformations
    pt1 = @first_node.hub.entity.bounds.center
    pt2 = @second_node.hub.entity.bounds.center
    pt3 = Geom::Point3d.linear_combination(0.5, pt1, 0.5, pt2)
    dir = pt2 - pt1

    return if dir.length.to_f < 1.0e-6

    elong1 = @children[0]
    elong2 = @children[3]
    bottle = @children[1]

    scale1 = Geom::Transformation.scaling(elong1.radius,
                                          elong1.radius,
                                          elong1.length)
    scale2 = Geom::Transformation.scaling(elong2.radius,
                                          elong2.radius,
                                          elong2.length)

    dir.normalize!
    t1 = Geom::Transformation.new(pt1, dir) * scale1
    t2 = Geom::Transformation.new(pt2, dir.reverse) * scale2
    t3 = Geom::Transformation.new(pt2 - Geometry.scale_vector(dir,
                                                              elong2.length),
                                  dir.reverse)

    elong1.entity.move!(t1)
    elong2.entity.move!(t2)
    bottle.entity.move!(t3)

    move_sensor_symbol(pt3)
  end

  def create_joints(world, first_node, second_node, breaking_force)
    # Associated nodes are to be connected with one joint:
    #   Node A connected to Node B by PointToPoint constraint.
    # The link object in between will not be part of physics simulation.
    bd1 = first_node.hub.body
    bd2 = second_node.hub.body
    pt1 = bd1.group.bounds.center
    pt2 = bd2.group.bounds.center
    @joint = TrussFab::PointToPoint.new(world, bd1, bd2, pt1, pt2, nil)
    @joint.solver_model = Configuration::JOINT_SOLVER_MODEL
    @joint.stiffness = Configuration::JOINT_STIFFNESS
    @joint.breaking_force = breaking_force
  end

  def reset_physics
    super
    @joint = nil
  end

  #
  # Children SketchupObject methods
  #

  def connect_to_hub
    @first_elongation.reset if @first_elongation
    @second_elongation.reset if @second_elongation
  end

  def disconnect_from_hub(is_first_joint, distance)
    if is_first_joint
      @first_elongation.shorten(distance) if @first_elongation
    else
      @second_elongation.shorten(distance) if @second_elongation
    end
  end

  def bottle_link
    @children.find { |child| child.is_a?(BottleLink) }
  end

  def elongations
    @children.select { |child| child.is_a? Elongation }
  end

  def direction
    @position.vector_to(@second_position)
  end

  def recreate_children
    delete_children
    create_children
  end

  def create_children
    create_elongations

    link_position = @position.offset(@first_elongation.direction)

    if Configuration::PIPE_MODE
      add(@first_elongation,
          PipeLink.new(link_position, direction, @model, id: @id),
          Line.new(@position, @second_position, LINK_LINE),
          @second_elongation)
    else
      add(@first_elongation,
          BottleLink.new(link_position, direction, @model, id: @id),
          Line.new(@position, @second_position, LINK_LINE),
          @second_elongation)
    end
  end

  def create_elongations
    @first_elongation.delete if @first_elongation
    @second_elongation.delete if @second_elongation

    length = @first_node.position.distance(@second_node.position)

    elongation_length = length - @model.length
    @first_elongation_length = elongation_length * @elongation_ratio
    @second_elongation_length = elongation_length * (1.0 - @elongation_ratio)

    @first_elongation = Elongation.new(@position,
                                       direction,
                                       @first_elongation_length)

    @second_elongation = Elongation.new(@second_position,
                                        direction.reverse,
                                        @second_elongation_length)
  end
end
