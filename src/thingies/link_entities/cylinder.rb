require 'src/thingies/thingy.rb'
require 'src/simulation/simulation.rb'

class Cylinder < Thingy

  attr_accessor :body

  def initialize(center, vector, parent, definition, id = nil)
    super(id)
    @center = center
    @vector = vector
    @definition = definition
    @body = nil
    @entity = create_entity
    @parent = parent
    persist_entity(type: parent.class.to_s, id: parent.id)
  end

  def create_body(world)
    @body = Simulation.create_body(world, @entity, collision_type: :cylinder)
    @body.mass = Simulation::PISTON_MASS / 2.0
    @body.collidable = false
    @body
  end

  def create_entity
    translation = Geom::Transformation.translation(@center)
    rotation_angle = Geometry.rotation_angle_between(Geometry::Z_AXIS,
                                                     @vector)
    rotation_axis = Geometry.perpendicular_rotation_axis(Geometry::Z_AXIS,
                                                         @vector)
    rotation = Geom::Transformation.rotation(@center,
                                             rotation_axis,
                                             rotation_angle)

    transformation = rotation * translation
    Sketchup.active_model.active_entities.add_instance(@definition,
                                                       transformation)
  end

  def change_color(color)
    @entity.definition.entities.each do |ent|
      if ent.material != color
        ent.material = color
        ent.material.alpha = 1.0
      end
    end
  end
end
