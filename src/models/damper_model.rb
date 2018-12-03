require 'src/models/physics_link_model.rb'

class DamperModel < PhysicsLinkModel
  def initialize
    super
    @material = Sketchup.active_model.materials['damper_material']
  end
end
