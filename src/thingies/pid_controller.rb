require 'src/thingies/physics_link.rb'
require 'src/configuration/configuration.rb'
require 'src/thingies/generic_link'

class PidController < GenericLink
  attr_accessor :target_length, :integral_error, :k_P, :k_I, :k_D
  def initialize(first_node, second_node, id: nil)
    super(first_node, second_node, link_type: 'pid_controller', id: id)

    @target_length = @default_length
    @integral_error = 0
    @previous_error = 0
    set_pid_values(50, 50, 50)
  end

  def update_force
    return unless @joint.valid?
    error = (@target_length - @joint.cur_distance)
    iteration_time = (Configuration::WORLD_TIMESTEP / Configuration::WORLD_NUM_ITERATIONS)
    @integral_error += error * iteration_time
    derivative_error = (error - @previous_error) / iteration_time

    self.force = @k_P * error + @k_D * derivative_error + @k_I * integral_error

    @previous_error = error

    puts "#{force.round(2)}|#{(@k_P * error).round(2)}|#{(@k_D * derivative_error).round(2)}|#{(@k_I * integral_error).round(2)}"
  end

  def set_pid_values(p, i, d)
    @k_P = p
    @k_I = i
    @k_D = d
  end

  def reset_errors
    @integral_error = 0
    @previous_error = 0
  end

end
