require 'src/sketchup_objects/sketchup_object.rb'
require 'src/simulation/simulation.rb'
require 'src/models/parametric_spring_model.rb'

# Spring
class Spring < SketchupObject
  attr_reader :material

  def initialize(start_position, vector, scale_factor, parent, definition, id = nil)
    super(id)
    @start = start_position
    @vector = vector
    @definition = definition
    if scale_factor.nil?
      @scale_factor = 1.0
    else
      @scale_factor = scale_factor
    end
    @entity = create_entity
    @parent = parent
    persist_entity(type: parent.class.to_s, id: parent.id)
  end

  def create_entity
    return @entity if @entity
    entity = Sketchup.active_model.active_entities.add_instance(@definition, get_transformation_from_position_direction);
    entity
  end

  def get_transformation_from_position_direction(start_position = @start,
                                                 direction = @vector,
                                                 scale_factor = @scale_factor)
    translation = Geom::Transformation.translation(start_position)
    rotation_angle = Geometry.rotation_angle_between(Geometry::Z_AXIS,
                                                     direction)
    rotation_axis = Geometry.perpendicular_rotation_axis(Geometry::Z_AXIS,
                                                         direction)
    rotation = Geom::Transformation.rotation(start_position,
                                             rotation_axis,
                                             rotation_angle)

    scaling = Geom::Transformation.scaling(start_position, 1, 1, scale_factor)

    transformation = rotation * scaling * translation
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
