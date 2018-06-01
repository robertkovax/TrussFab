require 'src/models/physics_link_model.rb'

# Spring model (green)
class SpringModel < PhysicsLinkModel
  def initialize
    super
    @material = Sketchup.active_model.materials['spring_material']
  end
end
