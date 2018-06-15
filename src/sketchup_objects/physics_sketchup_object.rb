require 'src/sketchup_objects/sketchup_object'
require 'src/simulation/simulation.rb'

# Moving SketchupObject, affected by physics
class PhysicsSketchupObject < SketchupObject
  def initialize(id, material: nil)
    if material.nil?
      super(id)
    else
      super(id, material: material)
    end
    @body = nil
  end

  def joint_position
    raise NotImplementedError
  end

  def create_body(_world)
    raise NotImplementedError
  end

  def reset_physics
    @body = nil
  end
end
