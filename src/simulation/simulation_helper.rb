module SimulationHelper

  ELONGATION_MASS = 3.0
  LINK_MASS = 15.0
  PISTON_MASS = 15.0
  HUB_MASS = 5.0

  DEFAULT_STIFFNESS = 1.0
  DEFAULT_FRICTION = 2.0
  DEFAULT_BREAKING_FORCE = 100_000

  PISTON_RATE = 0.1

  class << self
    def body_for(world, *thingies)
      entities = thingies.flat_map(&:all_entities)
      group = Sketchup.active_model.entities.add_group(entities)
      MSPhysics::Body.new(world, group, :convex_hull)
    end

    def joint_between(world, klass, parent_body, child_body, matrix, group = nil)
      joint = klass.new(world, parent_body, matrix, group)
      joint.stiffness = DEFAULT_STIFFNESS
      joint.breaking_force = DEFAULT_BREAKING_FORCE
      joint.friction = DEFAULT_FRICTION if klass == MSPhysics::Hinge
      joint.connect(child_body)
      joint
    end

    def create_piston(world, parent_body, child_body, matrix)
      piston = joint_between(world, MSPhysics::Piston, parent_body, child_body, matrix)
      piston.rate = PISTON_RATE
      piston
    end
  end
end