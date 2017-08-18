require 'src/utility/geometry.rb'
require 'src/configuration/configuration.rb'

class BottleModelFactory
  attr_reader :models

  def initialize(small_bottle_length, big_bottle_length)

    @big_length = big_bottle_length
    @small_length = small_bottle_length

    @big_big = create_double_bottle(true, true, Configuration::BIG_BIG_BOTTLE_NAME)
    @big_small = create_double_bottle(true, false, Configuration::SMALL_BIG_BOTTLE_NAME)
    @small_small = create_double_bottle(false, false, Configuration::SMALL_SMALL_BOTTLE_NAME)
    @models = [@small_small, @big_small, @big_big]
  end

  def create_double_bottle(is_big1, is_big2, name)
    definition = Sketchup.active_model.definitions.add(name)
    length1 = is_big1 ? @big_length : @small_length
    length2 = is_big2 ? @big_length : @small_length
    bottle1 = Bottle.new(length1, definition, is_big1)
    bottle2 = Bottle.new(length2, definition, is_big2)
    connect_bottles(bottle1, bottle2)
    BottleModel.new(definition, length1 + length2)
  end

  def longest_fitting_model(length)
    @models.select { |m| m.length <= length }.max_by(&:length)
  end

  def connect_bottles(lower_bottle, upper_bottle)
    upper_bottle.group.transform!(Geom::Transformation.scaling(upper_bottle.group.bounds.center, 1, 1, -1))
    upper_bottle.group.transform!(Geom::Transformation.translation(Geom::Vector3d.new(0, 0, lower_bottle.length)))
  end
end

class BottleModel
  attr_reader :definition, :length

  def initialize(definition, length)
    @length = length
    @definition = definition
  end

  def name
    @definition.name
  end
end

class Bottle
  attr_reader :group, :length

  BOTTLE_SEGMENTS = 10.freeze

  def initialize(length, definition, is_big = true)
    @is_big = is_big
    @group = definition.entities.add_group
    @length = length

    # neck
    cylinder(Geometry::ORIGIN,
             Geom::Point3d.new(0, 0, Configuration::NECK_LENGTH),
             Configuration::NECK_RADIUS)

    # front cone
    cone(Geom::Point3d.new(0, 0, Configuration::NECK_LENGTH),
         Geom::Point3d.new(0, 0, Configuration::NECK_LENGTH + Configuration::FRONT_CONE_LENGTH),
         Configuration::NECK_RADIUS,
         Configuration::CYLINDER_RADIUS)

    # main cylinder
    cylinder(Geom::Point3d.new(0, 0, Configuration::NECK_LENGTH + Configuration::FRONT_CONE_LENGTH),
             Geom::Point3d.new(0, 0, Configuration::NECK_LENGTH + Configuration::FRONT_CONE_LENGTH + Configuration::CYLINDER_LENGTH),
             Configuration::CYLINDER_RADIUS)

    # back cone
    cone(Geom::Point3d.new(0, 0, Configuration::NECK_LENGTH + Configuration::FRONT_CONE_LENGTH + Configuration::CYLINDER_LENGTH),
         Geom::Point3d.new(0, 0, Configuration::NECK_LENGTH + Configuration::FRONT_CONE_LENGTH + Configuration::CYLINDER_LENGTH + Configuration::BACK_CONE_LENGTH),
         Configuration::CYLINDER_RADIUS,
         Configuration::BOTTOM_RADIUS)


    # important to draw the circles at the end, else Sketchup's duplicate collector makes trouble
    circle(Geom::Point3d.new(0, 0, 0), Configuration::NECK_RADIUS)
    circle(Geom::Point3d.new(0, 0, Configuration::NECK_LENGTH + Configuration::FRONT_CONE_LENGTH + Configuration::CYLINDER_LENGTH + Configuration::BACK_CONE_LENGTH),
           Configuration::BOTTOM_RADIUS)

    scale_bottle

    if @is_big
      @group.material = Sketchup.active_model.materials['big_bottle_green']
    else
      @group.material = Sketchup.active_model.materials['small_bottle_green']
    end
  end

  def scale_bottle
    z_scale_factor = @length / model_length
    x_y_scale_factor = @is_big ? 1.3 : 1.0
    @group.transform!(Geom::Transformation.scaling(x_y_scale_factor,
                                                   x_y_scale_factor,
                                                   z_scale_factor))
  end

  def model_length
    Configuration::NECK_LENGTH + Configuration::FRONT_CONE_LENGTH + Configuration::CYLINDER_LENGTH + Configuration::BACK_CONE_LENGTH
  end

  def cone(start_position, end_position, start_radius, end_radius)
    vector = start_position.vector_to(end_position)
    start_circle_edges = @group.entities.add_circle(start_position, vector, start_radius, BOTTLE_SEGMENTS)
    end_circle_edges = @group.entities.add_circle(end_position, vector, end_radius, BOTTLE_SEGMENTS)

    start_circle_edges.zip(end_circle_edges) do |start_circle_edge, end_circle_edge|
      edge = @group.entities.add_line(start_circle_edge.start.position,
                                      end_circle_edge.start.position)
      edge.smooth = true
      edge.soft = true
      @group.entities.add_face(start_circle_edge.start.position,
                               end_circle_edge.start.position,
                               end_circle_edge.end.position,
                               start_circle_edge.end.position)
    end
  end

  def cylinder(start_position, end_position, radius)
    cone(start_position, end_position, radius, radius)
  end

  def circle(center, radius)
    circle_edges = @group.entities.add_circle(center,
                                              Geometry::Z_AXIS,
                                              radius,
                                              BOTTLE_SEGMENTS
    )
    @group.entities.add_face(circle_edges)
  end
end