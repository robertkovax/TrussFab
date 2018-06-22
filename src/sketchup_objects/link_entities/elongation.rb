# Elongation
class Elongation < SketchupObject
  attr_reader :direction, :radius

  def initialize(position, direction, length,
                 id: nil, material: 'elongation_material')
    super(id, material: material)
    @position = position
    @direction = direction
    @direction.length = length
    @model = ModelStorage.instance.models['connector']
    @radius = Configuration::ELONGATION_RADIUS
    @layer = Configuration::HUB_VIEW
    @original_transformation = nil
    @entity = create_entity
    persist_entity
  end

  def length
    @direction.length
  end

  def shorten(offset)
    @entity.transform! Geom::Transformation.translation(offset)
  end

  def reset
    @entity.transformation = @original_transformation
  end

  def resize(length)
    @parent.change_elongation_length(self, length)
  end

  private

  def create_entity
    return @entity if @entity
    scale = Geom::Transformation.scaling(@radius, @radius, length)
    translation = Geom::Transformation.translation(@position)

    rotation_angle = Geometry.rotation_angle_between(Geometry::Z_AXIS,
                                                     @direction)
    rotation_axis = Geometry.perpendicular_rotation_axis(Geometry::Z_AXIS,
                                                         @direction)
    rotation = Geom::Transformation.rotation(@position,
                                             rotation_axis, rotation_angle)

    transformation = rotation * translation * scale

    @original_transformation = transformation

    entity = Sketchup.active_model.entities.add_instance(@model.definition,
                                                         transformation)
    entity.material = @material
    entity.layer = @layer
    entity
  end
end
