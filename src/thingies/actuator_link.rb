require 'src/thingies/physics_link.rb'
require 'src/configuration/configuration.rb'

# ActuatorLink
class ActuatorLink < PhysicsLink
  attr_accessor :reduction, :rate, :power, :min, :max
  attr_reader :joint, :first_cylinder, :second_cylinder, :default_length

  def initialize(first_node, second_node, id: nil)
    super(first_node, second_node, 'actuator', id: id)

    pt1 = first_node.thingy.position
    pt2 = second_node.thingy.position
    @default_length = pt1.distance(pt2).to_m

    @reduction = Configuration::ACTUATOR_REDUCTION
    @rate = Configuration::ACTUATOR_RATE
    @power = Configuration::ACTUATOR_POWER
    @min = Configuration::ACTUATOR_MIN
    @max = Configuration::ACTUATOR_MAX

    persist_entity
  end

  #
  # Physics methods
  #
  def update_link_properties
    return unless @joint && @joint.valid?
    @joint.stiffness = 0.99
    @joint.rate = @rate
    @joint.reduction_ratio = @reduction
    @joint.power = @power
  end
end
