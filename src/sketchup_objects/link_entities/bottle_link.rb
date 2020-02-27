require 'src/configuration/configuration'

# BottleLink
class BottleLink < SketchupObject
  attr_reader :model, :direction

  def initialize(position, direction, model,
                 id: nil, material: 'bottle_material')
    super(id, material: material)
    @position = position
    @direction = direction
    @model = model
    @entity = create_entity
    @entity.material = @material

    persist_entity
  end

  private

  def create_entity
    return @entity if @entity

    scaling =
        Geom::Transformation.scaling(1, 1, @direction.length / @model.length)

    translation = Geom::Transformation.translation(@position)

    rotation_angle = Geometry.rotation_angle_between(Geometry::Z_AXIS,
                                                     @direction)
    rotation_axis = Geometry.perpendicular_rotation_axis(Geometry::Z_AXIS,
                                                         @direction)
    rotation = Geom::Transformation.rotation(@position,
                                             rotation_axis,
                                             rotation_angle)

    transformation = rotation * translation * scaling

    entity = Sketchup.active_model
                     .active_entities
                     .add_instance(@model.definition, transformation)
    entity.layer = Configuration::COMPONENT_VIEW

    entity
  end
end
