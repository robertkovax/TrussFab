require 'src/configuration/configuration.rb'

class ActuatorModel

  attr_accessor :length, :inner_piston, :outer_piston

  def initialize
    @length = 688.mm
    @center = Geom::Point3d.new
    @up_vector = Geom::Vector3d.new(0, 0, 1).normalize!
    @inner_piston = create_piston('inner_piston', 0.5)
    @outer_piston = create_piston('outer_piston', 1)
  end

  def create_piston(name, diameter)
    definition = Sketchup.active_model.definitions.add(name)
    circle_edgearray = definition.entities.add_circle(@center, @up_vector, diameter)
    face = definition.entities.add_face(circle_edgearray)
    face.pushpull(-2 * @length / 3, false)
    definition
  end
end