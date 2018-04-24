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
    @k_P = 100
    @k_I = 0
    @k_D = 0
  end

  def update_force
    return unless @joint.valid?
    error = (@target_length - @joint.cur_distance)
    iteration_time = (Configuration::WORLD_TIMESTEP / Configuration::WORLD_NUM_ITERATIONS)
    @integral_error += error * iteration_time
    derivative_error = (error - @previous_error) / iteration_time

    self.force = @k_P * error + @k_D * derivative_error + @k_I * integral_error

    puts "#{self.force}"
  end

end
