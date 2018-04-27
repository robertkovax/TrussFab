require 'src/configuration/configuration'

# BottleLink
class BottleLink < Thingy
  attr_reader :model, :direction

  def initialize(position, direction, model,
                 id: nil, material: 'bottle_material')
    super(id, material: material)
    @position = position
    @direction = direction
    @model = model
    @entity = create_entity
    @material = Sketchup.active_model.materials.add('bottle_link')
    @material.color = Configuration::BOTTLE_COLOR
    @entity.material = @material

    persist_entity
  end

  def highlight(highlight_material = @highlight_material)
    change_color(highlight_material)
  end

  def un_highlight
    change_color(@model.model.material.color)
  end

  def delete_entity
    super
    Sketchup.active_model.materials.remove(@material)
  end

  private

  def create_entity
    return @entity if @entity
    translation = Geom::Transformation.translation(@position)

    rotation_angle = Geometry.rotation_angle_between(Geometry::Z_AXIS,
                                                     @direction)
    rotation_axis = Geometry.perpendicular_rotation_axis(Geometry::Z_AXIS,
                                                         @direction)
    rotation = Geom::Transformation.rotation(@position,
                                             rotation_axis,
                                             rotation_angle)

    transformation = rotation * translation

    entity = Sketchup.active_model
                     .active_entities
                     .add_instance(@model.definition, transformation)
    entity.layer = Configuration::COMPONENT_VIEW

    entity
  end
end
