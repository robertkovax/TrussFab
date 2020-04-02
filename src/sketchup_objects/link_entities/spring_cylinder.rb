# SpringCylinder mounting a spring
class SpringCylinder < SketchupObject
  attr_reader :material

  CYLINDER_RADIUS = 0.5

  def initialize(parent, length, spring_length, spring_diameter, id = nil)
    super(id)
    @definition = create_cylinder(Geom::Point3d.new, Geom::Vector3d.new(0, 0, 1), length,
                                  spring_length / 2, spring_diameter)
    @entity = create_entity
    @parent = parent
    persist_entity(type: parent.class.to_s, id: parent.id)
  end

  def create_entity
    return @entity if @entity

    Sketchup.active_model.active_entities.
        add_instance(@definition, Geom::Transformation.new);
  end

  def material=(material)
    @material = material
    change_color(material)
  end

  def change_color(color)
    @entity.material = color
    @entity.material.alpha = 1.0
  end

  def create_cylinder(center, up_vector, length, fix_plates_offset, spring_diameter)
    segment_number = 24
    spring_center_position = center + Geometry.scale_vector(up_vector, length / 2)
    definition = Sketchup.active_model.definitions.add("spring_cylinder_#{@id}")

    # Add cylinder connecting both nodes (with small diameter)
    circle_edgearray = definition.entities.add_circle(center, up_vector, CYLINDER_RADIUS, segment_number)
    face = definition.entities.add_face(circle_edgearray)
    face.pushpull(-length, false)

    # Add thin inner piston cylinder
    circle_edgearray = definition.entities.add_circle(spring_center_position, up_vector, CYLINDER_RADIUS * 1.25,
                                                      segment_number)
    face = definition.entities.add_face(circle_edgearray)
    face.pushpull(-fix_plates_offset, false)

    # Add thick inner piston cylinder
    circle_edgearray = definition.entities.add_circle(spring_center_position, up_vector,
                                                      CYLINDER_RADIUS * 2.0, segment_number)
    face = definition.entities.add_face(circle_edgearray)
    face.pushpull(fix_plates_offset, false)

    # Add fixing plates, restricting spring
    plate_height = 0.5
    spring_start = spring_center_position + Geometry.scale_vector(up_vector.normalize.reverse!, fix_plates_offset)
    spring_end = spring_center_position + Geometry.scale_vector(up_vector.normalize, fix_plates_offset)

    start_circle_edgearray = definition.entities.add_circle(spring_start, up_vector.reverse, spring_diameter, segment_number)
    face = definition.entities.add_face(start_circle_edgearray)
    face.pushpull(plate_height, false)
    end_circle_edgearray = definition.entities.add_circle(spring_end, up_vector, spring_diameter, segment_number)
    face = definition.entities.add_face(end_circle_edgearray)
    face.pushpull(plate_height, false)

    definition.entities.each do |entity|
      entity.layer = Configuration::ACTUATOR_VIEW
    end
    definition
  end
end
