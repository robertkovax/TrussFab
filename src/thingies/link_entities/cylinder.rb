require 'src/thingies/link_entities/link_entity.rb'
require 'src/simulation/simulation.rb'

class Cylinder < LinkEntity

  attr_accessor :body

  def initialize(center, vector, definition, id = nil)
    @center = center
    @vector = vector
    @definition = definition
    @body = nil
    super(id)
  end

  def create_body(world)
    @body = Simulation.create_body(world, @entity, collision_type: :cylinder)
    @body.mass = Simulation::PISTON_MASS
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
end