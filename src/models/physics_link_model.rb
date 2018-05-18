require 'src/configuration/configuration.rb'

# Super Class for moving link models
class PhysicsLinkModel
  attr_reader :length, :inner_cylinder, :outer_cylinder, :material

  def initialize(length = nil)
    @length = length.nil? ? 688.mm : length
    @center = Geom::Point3d.new
    @up_vector = Geom::Vector3d.new(0, 0, 1).normalize!
    @inner_cylinder = create_cylinder('inner_piston_cylinder', 0.5)
    @outer_cylinder = create_cylinder('outer_piston_cylinder', 1)
    @material = Sketchup.active_model.materials['standard_material']
  end

  def valid?
    @inner_cylinder.valid? && @outer_cylinder.valid?
  end

  def create_cylinder(name, diameter)
    definition = Sketchup.active_model.definitions.add(name)
    circle_edgearray = definition.entities.add_circle(@center,
                                                      @up_vector,
                                                      diameter, 12)
    face = definition.entities.add_face(circle_edgearray)
    face.pushpull(-2 * @length / 3, false)
    definition.entities.each do |entity|
      entity.layer = Configuration::ACTUATOR_VIEW
    end
    definition
  end
end
