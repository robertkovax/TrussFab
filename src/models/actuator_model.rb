require 'src/models/physics_link_model.rb'

# ActuatorModel
class ActuatorModel < PhysicsLinkModel
  def initialize
    super
    @material = Sketchup.active_model.materials['actuator_material']
  end
end
