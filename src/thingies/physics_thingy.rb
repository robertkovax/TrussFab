require 'src/thingies/thingy'
require 'src/simulation/simulation_helper.rb'

class PhysicsThingy < Thingy

  def initialize(id)
    super(id)
    @body = nil
  end

  def joint_position
    raise NotImplementedError
  end

  def create_body(world)
    raise NotImplementedError
  end

  def joint_to(world, klass, other_body, direction, group = nil)
    matrix = Geom::Transformation.new(joint_position, direction)
    SimulationHelper.joint_between(world, klass, body, other_body, matrix, group)
  end
end