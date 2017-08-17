class BottleLink < Thingy
  attr_reader :model

  def initialize(position, direction, model,
                 id: nil)
    super(id)
    @position = position
    @direction = direction
    @model = model
    @entity = create_entity
  end

  private

  def create_entity
    return @entity if @entity
    translation = Geom::Transformation.translation(@position)

    rotation_angle = Geometry.rotation_angle_between(Geometry::Z_AXIS, @direction)
    rotation_axis = Geometry.perpendicular_rotation_axis(Geometry::Z_AXIS, @direction)
    rotation = Geom::Transformation.rotation(@position, rotation_axis, rotation_angle)

    transformation = rotation * translation

    entity = Sketchup.active_model.active_entities.add_instance(@model.definition, transformation)
    entity.layer = Configuration::COMPONENT_VIEW
    entity
  end
end
