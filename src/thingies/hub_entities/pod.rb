class Pod < Thingy
  def initialize(position, direction, id: nil)
    super(id)
    @position = position
    @direction = direction
    @color = Configuration::ELONGATION_COLOR
    @model = ModelStorage.instance.models['pod']
    @entity = create_entity
  end

  def distance(point)
    # offset first point to factor in the visible hub radius
    first_point = @position.offset(@direction, Configuration::BALL_HUB_RADIUS/2)
    second_point = @position + @direction
    Geometry.dist_point_to_segment(point, [@position, second_point])
  end

  def highlight
    change_color(@highlight_color)
  end

  def un_highlight
    change_color(@color)
  end

  def update_position(position)
    @position = position
    delete_entity
    @entity = create_entity
  end

  private

  def create_entity
    translation = Geom::Transformation.translation(@position)

    rotation_angle = Geometry.rotation_angle_between(Geometry::Z_AXIS, @direction)
    rotation_axis = Geometry.perpendicular_rotation_axis(Geometry::Z_AXIS, @direction)
    rotation = Geom::Transformation.rotation(@position, rotation_axis, rotation_angle)

    transformation = rotation * translation

    entity = Sketchup.active_model.active_entities.add_instance(@model.definition, transformation)
    entity.material = @color
    entity
  end
end