require 'src/sketchup_objects/link_entities/bottle_link.rb'
#Pipe Link
class PipeLink < BottleLink
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
    scaling = Geom::Transformation.scaling(1,1, @model.length.to_cm)

    transformation = rotation * translation * scaling

    entity = Sketchup.active_model
                     .active_entities
                     .add_instance(@model.definition, transformation)
    entity.layer = Configuration::COMPONENT_VIEW

    entity
 end
end
