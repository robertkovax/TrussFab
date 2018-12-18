require 'src/sketchup_objects/generic_link.rb'
require 'src/configuration/configuration.rb'

# PhysicsLink that behaves like a gas spring
class SpringDamperLink < GenericLink
  attr_accessor :spring_constant, :damping_coefficient, :last_length

  def initialize(first_node, second_node, edge, id: nil, spring_constant: 1000, damping_coefficient: 50)
    super(first_node, second_node, edge, id: id)
    
    @spring_constant = spring_constant
    @damping_coefficient = damping_coefficient
    @initial_force = 0
    @force = @initial_force
    @last_length = length_current
    change_color(Sketchup.active_model.materials['spring_damper_material'])

    persist_entity
  end

  #
  # Physics methods
  #

  def update_force(time_per_step)
    velocity = (length_current - @last_length)/time_per_step
    
    if velocity == 0
      damping_force = @initial_force
    else
      #Stop damping effect shortly before the minimum distance to reduce the chance of crashing the simulation
      if (length_current - min_distance) >= min_distance/1000
        damping_force = - velocity * damping_coefficient
      else
        damping_force = 0
      end
    end
    
    spring_force = (@default_length - length_current) * @spring_constant
    self.force = damping_force + spring_force
    @last_length = length_current
  end
end
