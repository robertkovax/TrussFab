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
	@force = 0
	@last_length = length_current

    persist_entity
  end

  #
  # Physics methods
  #

  def update_force(time_per_step)
    velocity = (length_current - @last_length)/time_per_step
	if (length_current - min_distance) >= 0
	  self.force = - velocity * damping_coefficient
	else
	  self.force = 0
	end
	if DamperLink.debug
	  puts "DamperLink: #{id}, Velocity: #{velocity}, F:#{@force}, to_go: #{length_current - min_distance}"
	end
	@last_length = length_current
  end
end
