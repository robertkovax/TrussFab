require 'src/sketchup_objects/generic_link.rb'
require 'src/configuration/configuration.rb'

class DamperLink < GenericLink
  attr_accessor :damping_coefficient, :last_length
  
  class << self
	attr_accessor :debug
	@debug = true
  end

  def initialize(first_node, second_node, edge, id: nil, damping_coefficient: 1000)
    super(first_node, second_node, edge, id: id)

	#puts "metal spring object initialized"
	
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
	  if (length_current - min_distance) >= min_distance/1000
	    force = - velocity * damping_coefficient
	    #if force > (5*9.81)
		  #force = 5*9.81
	    #end
	    self.force = force
	  else
	    self.force = 0
	  end
	end
	
	if DamperLink.debug
	  puts "DamperLink: #{id}, Velocity: #{velocity}, F:#{@force}, to_go: #{length_current - min_distance}"
	end
	@last_length = length_current
  end
end
