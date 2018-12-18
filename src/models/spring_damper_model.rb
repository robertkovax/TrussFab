require 'src/models/physics_link_model.rb'

class SpringDamperModel < PhysicsLinkModel
  def initialize
    super
    @material = Sketchup.active_model.materials['spring_damper_material']
  end
end
