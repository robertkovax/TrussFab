require 'src/thingies/physics_link.rb'
require 'src/configuration/configuration.rb'

class GenericLink < PhysicsLink

  attr_accessor :min_distance, :max_distance
  attr_reader :joint, :first_cylinder, :second_cylinder

  def initialize(first_node, second_node, id: nil)
    super(first_node, second_node, 'generic', id: id)

    @force = Configuration::GENERIC_LINK_FORCE
    @min_distance = Configuration::GENERIC_LINK_MIN_DISTANCE
    @max_distance = Configuration::GENERIC_LINK_MAX_DISTANCE
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
    unless @joint.nil?
      @joint.force = force
      @joint.update_info
    end
  end

  def force
    @force
  end
end
