class Pod < Thingy
  def initialize(position, direction, id: nil)
    super(id)
    @position = position
    @direction = direction
    @color = Sketchup.active_model.materials['elongation_color']
    @model = ModelStorage.instance.models['pod']
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