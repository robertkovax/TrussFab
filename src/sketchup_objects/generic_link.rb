require 'src/sketchup_objects/physics_link.rb'
require 'src/configuration/configuration.rb'

# GenericLink
class GenericLink < PhysicsLink
  attr_accessor :min_distance, :max_distance
  attr_reader :joint, :first_cylinder, :second_cylinder, :initial_force,
              :default_length, :force

  def initialize(first_node, second_node, id: nil, link_type: 'generic')
    super(first_node, second_node, link_type, id: id)

    pt1 = first_node.hub.position
    pt2 = second_node.hub.position
    @default_length = pt1.distance(pt2).to_m

    @force = 0
    @min_distance = @default_length + Configuration::GENERIC_LINK_MIN_DISTANCE
    @max_distance = @default_length + Configuration::GENERIC_LINK_MAX_DISTANCE
    @limits_enabled = true

    persist_entity
  end

  #
  # Physics methods
  #

  def update_link_properties
    return unless @joint && @joint.valid?
    @joint.force = @force
    @joint.min_distance = @min_distance
    @joint.max_distance = @max_distance
    @joint.limits_enabled = @limits_enabled
  end

  def force=(force)
    @force = force
    return if @joint.nil? || !@joint.valid?
    @joint.force = force
    @joint.update_info
  end
end
