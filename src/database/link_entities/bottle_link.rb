require 'src/database/link_entities/link_entity.rb'

class BottleLink < LinkEntity
  def initialize(position, direction, definition, id: nil)
    super id
    @position = position
    @direction = direction
    @definition = definition
    create_entity
  end

  private

  def create_entity
    return @entity if @entity
    translation = Geom::Transformation.translation(@position)

    rotation_angle = Geometry.rotation_angle_between(Geometry::Z_AXIS, @direction)
    rotation_axis = Geometry.perpendicular_rotation_axis(Geometry::Z_AXIS, @direction)
    rotation = Geom::Transformation.rotation(@position, rotation_axis, rotation_angle)

    transformation = rotation * translation

    @entity = Sketchup.active_model.active_entities.add_instance(@definition, transformation)
    @entity.layer = Configuration::COMPONENT_VIEW
    @entity
  end
end
