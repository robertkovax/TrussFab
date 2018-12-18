require 'src/sketchup_objects/generic_link.rb'
require 'src/configuration/configuration.rb'

class DamperLink < GenericLink
  attr_accessor :damping_coefficient, :last_length
  
  def initialize(first_node, second_node, edge, id: nil, damping_coefficient: 50)
    super(first_node, second_node, edge, id: id)
	
    @damping_coefficient = damping_coefficient
    @last_length = length_current
    @initial_force = 5*9.81
    @force = @initial_force

    persist_entity
  end

  #
  # Physics methods
  #

  def update_force(time_per_step)
    velocity = (length_current - @last_length)/time_per_step
    if velocity == 0
      self.force = @initial_force
    else
      #Stop damping effect shortly before the minimum distance to reduce the chance of crashing the simulation
      if (length_current - min_distance) >= min_distance/1000
        self.force = - velocity * damping_coefficient
      else
        self.force = 0
      end
    end
    @last_length = length_current
  end
end
