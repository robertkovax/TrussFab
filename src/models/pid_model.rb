require 'src/models/physics_link_model.rb'

class PIDModel < PhysicsLinkModel
  def initialize
    super
    @material = Sketchup.active_model.materials['pid_material']
  end
end
