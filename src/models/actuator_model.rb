require 'src/configuration/configuration.rb'

class ActuatorModel

  attr_reader :length, :inner_cylinder, :outer_cylinder

  def initialize
    @length = 688.mm
    @center = Geom::Point3d.new
    @up_vector = Geom::Vector3d.new(0, 0, 1).normalize!
    @inner_cylinder = create_cylinder('inner_piston_cylinder', 0.5)
    @outer_cylinder = create_cylinder('outer_piston_cylinder', 1)
  end

  def create_cylinder(name, diameter)
    definition = Sketchup.active_model.definitions.add(name)
    circle_edgearray = definition.entities.add_circle(@center,
                                                      @up_vector,
                                                      diameter)
    face = definition.entities.add_face(circle_edgearray)
    face.pushpull(-2 * @length / 3, false)
    definition
  end
end