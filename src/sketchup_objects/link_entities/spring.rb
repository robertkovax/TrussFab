require 'src/sketchup_objects/sketchup_object.rb'
require 'src/simulation/simulation.rb'

# Spring
class Spring < SketchupObject
  attr_reader :material

  def initialize(center, vector, parent, definition, id = nil)
    super(id)
    @center = center
    @vector = vector
    @definition = definition
    @entity = create_entity
    @parent = parent
    persist_entity(type: parent.class.to_s, id: parent.id)
  end

  def create_entity
    return @entity if @entity
    entity = Sketchup.active_model.active_entities.add_instance(@definition, get_transformation_from_position_direction);
    entity
  end

  def get_transformation_from_position_direction(center_position=@center, direction=@vector)
    translation = Geom::Transformation.translation(center_position)
    rotation_angle = Geometry.rotation_angle_between(Geometry::Z_AXIS,
                                                     direction)
    rotation_axis = Geometry.perpendicular_rotation_axis(Geometry::Z_AXIS,
                                                         direction)
    rotation = Geom::Transformation.rotation(center_position,
                                             rotation_axis,
                                             rotation_angle)
    transformation = rotation * translation
    transformation
  end

  def material=(material)
    @material = material
    change_color(material)
  end

  def change_color(color)
    @entity.material = color
    @entity.material.alpha = 1.0
  end
end
