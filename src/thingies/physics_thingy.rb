require 'src/thingies/thingy'
require 'src/simulation/simulation.rb'

class PhysicsThingy < Thingy

  def initialize(id)
    super(id)
    @body = nil
  end

  def joint_position
    raise NotImplementedError
  end

  def create_body(_world)
    raise NotImplementedError
  end

  def joint_to(world, klass, other_body, pin_direction, group: nil, solver_model: 2)
    matrix = Geom::Transformation.new(joint_position, pin_direction)
    Simulation.joint_between(world,
                             klass,
                             body,
                             other_body,
                             matrix,
                             solver_model,
                             group)
  end
end