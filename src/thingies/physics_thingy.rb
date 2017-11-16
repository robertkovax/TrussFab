require 'src/thingies/thingy'
require 'src/simulation/simulation.rb'

class PhysicsThingy < Thingy

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

  def joint_to(world, klass, other_body, pin_direction, group: nil, solver_model: 16)
    joint_from_to(world, klass, @body, other_body, pin_direction, group: group, solver_model: solver_model)
  end

  def joint_from_to(world, klass, body, other_body, pin_direction, group: nil, solver_model: 16)
    matrix = Geom::Transformation.new(joint_position, pin_direction)
    Simulation.joint_between(world,
                             klass,
                             @body,
                             other_body,
                             matrix,
                             solver_model,
                             group)
  end

  def reset_physics
    @body = nil
  end
end
