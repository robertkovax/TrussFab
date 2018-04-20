require 'src/models/physics_link_model.rb'

# GenericLinkModel (orange)
class GenericLinkModel < PhysicsLinkModel
  def initialize
    super
    @material = Sketchup.active_model.materials['generic_link_material']
  end
end
