require 'src/thingies/physics_link.rb'
require 'src/configuration/configuration.rb'

# GenericLink
class GenericLink < PhysicsLink
  attr_accessor :min_distance, :max_distance
  attr_reader :joint, :first_cylinder, :second_cylinder, :initial_force,
              :default_length, :force

  def initialize(first_node, second_node, id: nil)
    super(first_node, second_node, 'generic', id: id)

    pt1 = first_node.thingy.position
    pt2 = second_node.thingy.position
    @default_length = pt1.distance(pt2).to_m

    length = pt1.distance(pt2).to_m

    @force = 0
    @min_distance = length - Configuration::GENERIC_LINK_MIN_DISTANCE
    @max_distance = length + Configuration::GENERIC_LINK_MAX_DISTANCE
    @limits_enabled = true

    persist_entity
  end

  #
  # Physics methods
  #

  def update_link_properties
    if @joint && @joint.valid?
      @joint.force = @force
      @joint.min_distance = @min_distance
      @joint.max_distance = @max_distance
      @joint.limits_enabled = @limits_enabled
    end
  end

  def force=(force)
    @force = force
    return if @joint.nil? || !@joint.valid?
    @joint.force = force
    @joint.update_info
  end

  def update_force_as_linear_spring
    return unless @joint.valid? # joint becomes invalid when it breaks
    self.force = 3000 * (@initial_length - @joint.cur_distance) - 50*(@joint.cur_velocity)
  end
end
