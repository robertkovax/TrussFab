require 'src/utility/geometry.rb'

class BottleModelFactory
  def initialize (big_big_length, big_small_length, small_small_length, segments = Configuration::BOTTLE_SEGMENTS)
    @segments = segments

    big_big = make_big_big_bottle(big_big_length)
    big_small = make_big_small_bottle(big_small_length)
    small_small = make_small_small_bottle(small_small_length)
  end

  def make_big_big_bottle(length)
    first_bottle = Bottle.new(length / 2, @segments)
    second_bottle = Bottle.new(length / 2, @segments)
    make_double_bottle(first_bottle, second_bottle)
  end

  def make_big_small_bottle(length)
    small_bottle = Bottle.new(length * 0.54, @segments)
    big_bottle = Bottle.new(length * 0.46, @segments)
    make_double_bottle(small_bottle, big_bottle)
  end

  def make_small_small_bottle(length)
    first_bottle = Bottle.new(length / 2, @segments)
    second_bottle = Bottle.new(length / 2, @segments)
    make_double_bottle(first_bottle, second_bottle)
  end

  def make_double_bottle(lower_bottle, upper_bottle)
    upper_bottle.group.transform!(Geom::Transformation.scaling(upper_bottle.group.bounds.center, 1, 1, -1))
    upper_bottle.group.transform!(Geom::Transformation.translation(Geom::Vector3d.new(0, 0, lower_bottle.length)))
    group = Sketchup.active_model.entities.add_group
    group.entities.add(upper_bottle.group, lower_bottle.group)
  end
end

class Bottle
  def initialize(length, segments)
    @group = Sketchup.active_model.entities.add_group
    @segments = segments
    # neck
    cylinder(Geometry::ORIGIN,
             Geom::Point3d.new(0, 0, Configuration::NECK_LENGTH),
             Configuration::NECK_RADIUS)

    # front cone
    cone(Geom::Point3d.new(0, 0, Configuration::NECK_LENGTH),
         Geom::Point3d.new(0,0,Configuration::NECK_LENGTH + Configuration::FRONT_CONE_LENGTH),
         Configuration::NECK_RADIUS,
         Configuration::CYLINDER_RADIUS)

    # main cylinder
    cylinder(Geom::Point3d.new(0,0,Configuration::NECK_LENGTH + Configuration::FRONT_CONE_LENGTH),
             Geom::Point3d.new(0,0,Configuration::NECK_LENGTH + Configuration::FRONT_CONE_LENGTH + Configuration::CYLINDER_LENGTH),
             Configuration::CYLINDER_RADIUS)

    # back cone
    cone(Geom::Point3d.new(0,0,Configuration::NECK_LENGTH + Configuration::FRONT_CONE_LENGTH + Configuration::CYLINDER_LENGTH),
         Geom::Point3d.new(0,0,Configuration::NECK_LENGTH + Configuration::FRONT_CONE_LENGTH + Configuration::CYLINDER_LENGTH + Configuration::BACK_CONE_LENGTH),
         Configuration::CYLINDER_RADIUS,
         Configuration::BOTTOM_RADIUS)


    # important to draw the circles at the end, else Sketchup's duplicate collector makes trouble
    circle(Geom::Point3d.new(0,0,0),
                 Configuration::NECK_RADIUS)
    circle(Geom::Point3d.new(0,0,Configuration::NECK_LENGTH + Configuration::FRONT_CONE_LENGTH + Configuration::CYLINDER_LENGTH + Configuration::BACK_CONE_LENGTH),
                    Configuration::BOTTOM_RADIUS)

    scalar = self.length / length
    @group.transform!(Geom::Transformation.scaling(1, 1, scalar))

    @group.material = Sketchup.active_model.materials['bottle_green']
  end

  def length
    Configuration::NECK_LENGTH + Configuration::FRONT_CONE_LENGTH + Configuration::CYLINDER_LENGTH + Configuration::BACK_CONE_LENGTH
  end

  def cone(start_position, end_position, start_radius, end_radius)
    vector = start_position.vector_to(end_position)
    start_circle_edges = @group.entities.add_circle(start_position, vector, start_radius, @segments)
    end_circle_edges = @group.entities.add_circle(end_position, vector, end_radius, @segments)

    start_circle_edges.zip(end_circle_edges) do |start_circle_edge, end_circle_edge|
      edge = @group.entities.add_line(start_circle_edge.start_position,
                                      end_circle_edge.start_position)
      edge.smooth = true
      edge.soft = true
      @group.entities.add_face(start_circle_edge.start_position,
                                      end_circle_edge.start_position,
                                      end_circle_edge.end_position,
                                      start_circle_edge.end_position)
    end
  end

  def cylinder(start_position, end_position, radius)
    cone(start_position, end_position, radius, radius)
  end

  def circle(center, radius)
    circle_edges = @group.entities.add_circle(center,
                                              Geometry::Z_AXIS,
                                              radius,
                                              @segments
    )
    @group.entities.add_face(circle_edges)
  end
end