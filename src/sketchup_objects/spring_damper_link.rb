require 'src/sketchup_objects/generic_link.rb'
require 'src/configuration/configuration.rb'

# PhysicsLink that behaves like a gas spring
class SpringDamperLink < GenericLink
  attr_accessor :spring_constant, :damping_coefficient, :last_length
  
  class << self
	attr_accessor :debug
	@debug = false
  end

  def initialize(first_node, second_node, edge, id: nil, spring_constant: 1000, damping_coefficient: 1000)
    super(first_node, second_node, edge, id: id)

	#puts "metal spring object initialized"
	
    @spring_constant = spring_constant
    @damping_coefficient = damping_coefficient
	@initial_force = 0
	@force = @initial_force
	@last_length = length_current

    persist_entity
  end

  #
  # Physics methods
  #

  def update_force(time_per_step)
	velocity = (length_current - @last_length)/time_per_step
	damping_force = -velocity * damping_coefficient
	spring_force = (@default_length - length_current) * @spring_constant
	self.force = damping_force + spring_force	
	if SpringDamperLink.debug
	  puts "SpringDamperLink: #{id}, Spring:#{spring_force}, Damper: #{damping_force}"
	end
	@last_length = length_current
  end
end
