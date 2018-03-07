require 'src/thingies/physics_link.rb'
require 'src/configuration/configuration.rb'

class GenericLink < PhysicsLink

  attr_accessor :min_distance, :max_distance
  attr_reader :joint, :first_cylinder, :second_cylinder

  def initialize(first_node, second_node, id: nil)
    super(first_node, second_node, 'generic', id: id)

    pt1 = first_node.thingy.position
    pt2 = second_node.thingy.position
    length = pt1.distance(pt2).to_m

    @force = Configuration::GENERIC_LINK_FORCE
    @min_distance = length - 0.2
    @max_distance = length + 0.2
    @limits_enabled = true
    @extended_force = Configuration::GENERIC_LINK_FORCE

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

  def update_force_as_linear_spring
    self.force = 500 * (@initial_length - @joint.cur_distance) - 50*(@joint.cur_velocity)
  end
end
