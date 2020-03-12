# SpringCylinder mounting a spring
class SpringCylinder < SketchupObject
  attr_reader :material

  def initialize(parent, length, diameter, id = nil)
    super(id)
    @definition = create_cylinder(Geom::Point3d.new, Geom::Vector3d.new(0, 0, 1),length, diameter,
                                  "spring_cylinder_#{id}")
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

  def create_cylinder(center, up_vector, length, diameter, name)
    definition = Sketchup.active_model.definitions.add(name)
    circle_edgearray = definition.entities.add_circle(center,
                                                      up_vector,
                                                      diameter, 12)
    face = definition.entities.add_face(circle_edgearray)
    face.pushpull(-length, false)
    definition.entities.each do |entity|
      entity.layer = Configuration::ACTUATOR_VIEW
    end
    definition
  end
end
