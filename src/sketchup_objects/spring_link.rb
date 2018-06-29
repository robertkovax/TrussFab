require 'src/sketchup_objects/physics_link.rb'
require 'src/configuration/configuration.rb'

# PhysicsLink that behaves like a gas spring
class SpringLink < PhysicsLink
  attr_accessor :extended_length, :stroke_length, :extended_force, :threshold,
                :damp

  def initialize(first_node, second_node, edge, id: nil)
    super(first_node, second_node, edge,'spring', id: id)

    @stroke_length = Configuration::SPRING_STROKE_LENGTH
    @extended_force = Configuration::SPRING_EXTENDED_FORCE
    @threshold = Configuration::SPRING_THRESHOLD
    @damp = Configuration::SPRING_DAMP

    persist_entity
  end

  #
  # Physics methods
  #

  def update_link_properties
    return unless @joint && @joint.valid?
    @joint.stroke_length = @stroke_length
    @joint.extended_force = @extended_force
    @joint.threshold = @threshold
    @joint.damp = @damp
  end
end
