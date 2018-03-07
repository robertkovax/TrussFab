require 'src/models/physics_link_model.rb'

class SpringModel < PhysicsLinkModel
  def initialize
    super
    @material = Sketchup.active_model.materials['spring_material']
  end
end
