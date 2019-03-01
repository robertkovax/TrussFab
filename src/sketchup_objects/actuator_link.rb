require 'src/sketchup_objects/physics_link.rb'
require 'src/configuration/configuration.rb'

# ActuatorLink
class ActuatorLink < PhysicsLink
  attr_accessor :reduction, :rate, :power, :min, :max
  attr_reader :default_length

  COLORS = [
    '#3cb44b', '#ffe119', '#f58231', '#911eb4', '#46f0f0', '#f032e6', '#d2f53c',
    '#fabebe', '#008080', '#e6beff', '#aa6e28', '#800000', '#aaffc3', '#808000',
    '#ffd8b1', '#000080', '#808080', '#000000'
  ].freeze

  def initialize(first_node, second_node, edge, id: nil)
    super(first_node, second_node, edge,'actuator', id: id)

    pt1 = first_node.hub.position
    pt2 = second_node.hub.position
    @default_length = pt1.distance(pt2).to_m

    @reduction = Configuration::ACTUATOR_REDUCTION
    @rate = Configuration::ACTUATOR_RATE
    @power = Configuration::ACTUATOR_POWER
    @min = (-2 * length / 3) / 100 # Configuration::ACTUATOR_MIN
    @max = (2 * length / 3) / 100 # Configuration::ACTUATOR_MAX

    persist_entity
  end

  def update_limits
    @min = (-2 * length / 3) / 100 # Configuration::ACTUATOR_MIN
    @max = (2 * length / 3) / 100 # Configuration::ACTUATOR_MAX
  end

  def piston_group=(piston_group)
    @piston_group = piston_group
    self.material = COLORS[piston_group]
  end

  def set_piston_group_color
    self.material = COLORS[@piston_group]
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
