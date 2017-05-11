require 'src/thingies/link_entities/link_entity.rb'
require 'src/utility/geometry.rb'

class Connector < LinkEntity
  attr_reader :direction

  def initialize(position, direction, length, id: nil)
    @position = position
    @direction = direction
    @direction.length = length
    @model = ModelStorage.instance.models['connector']
    @color = Configuration::CONNECTOR_COLOR
    @radius = Configuration::CONNECTOR_RADIUS
    @layer = Configuration::CONNECTOR_MODE_VIEW
    super(id)
  end

  def length
    @direction.length
  end

  private

  def create_entity
    return @entity if @entity
    scale = Geom::Transformation.scaling(@radius, @radius, length)
    translation = Geom::Transformation.translation(@position)

    rotation_angle = Geometry.rotation_angle_between(Geometry::Z_AXIS, @direction)
    rotation_axis = Geometry.perpendicular_rotation_axis(Geometry::Z_AXIS, @direction)
    rotation = Geom::Transformation.rotation(@position, rotation_axis, rotation_angle)

    transformation = rotation * translation * scale

    entity = Sketchup.active_model.entities.add_instance(@model.definition, transformation)
    entity.material = @color
    entity.layer = @layer
    entity
  end
end
