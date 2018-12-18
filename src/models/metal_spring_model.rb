require 'src/models/physics_link_model.rb'

# MetalSpringModel (orange)
class MetalSpringModel < PhysicsLinkModel
  def initialize
    super
    @material = Sketchup.active_model.materials['metal_spring_material']
  end
end
