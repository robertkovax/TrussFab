require 'src/thingies/physics_link.rb'
require 'src/configuration/configuration.rb'

class ActuatorLink < PhysicsLink

  attr_accessor :reduction, :rate, :power, :min, :max
  attr_reader :joint, :first_cylinder, :second_cylinder

  def initialize(first_node, second_node, id: nil)
    super(first_node, second_node, 'actuator', id: id)

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
    if @joint && @joint.valid?
      @joint.rate = @rate
      @joint.reduction_ratio = @reduction
      @joint.power = @power
    end
  end
end
