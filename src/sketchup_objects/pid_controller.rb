require 'src/sketchup_objects/physics_link.rb'
require 'src/configuration/configuration.rb'
require 'src/sketchup_objects/generic_link.rb'

class PidController < GenericLink
  attr_accessor :integral_error, :k_P, :k_I, :k_D, :integral_error_cap,
                :static_force, :static_forces_lookup, :use_static_lookup_force
  attr_reader :target_length, :logging

  def target_length=(length)
    @target_length = length
    reset_errors
  end

  def logging=(val)
    @logging = val
    if @logging
      puts 'Error(cm)|Force|P_Force|I_Force|D_Force|Lookup Static Error'
    end
  end

  def initialize(first_node, second_node, id: nil)
    super(first_node, second_node, link_type: 'pid_controller', id: id)

    @logging = false
    @integral_error_cap = 1
    @target_length = @default_length.round(4)
    @integral_error = 0
    @previous_error = nil
    @static_force = 0
    @static_forces_lookup = []
    @use_static_lookup_force = false
    set_pid_values(50, 50, 50)
  end

  def lookup_static_force
    return 0 if @static_forces_lookup.empty?
    # TODO: Do linear interpolation between the two positions in the array
    pos = normalized_position
    index = (pos * Configuration::STATIC_FORCE_ANALYSIS_STEPS).round(2)
    @static_forces_lookup[index]
  end

  def normalized_position
    (@joint.cur_distance - @min_distance) / (@max_distance - @min_distance)
  end

  def update_force
    return unless @joint.valid?
    error = (@target_length - @joint.cur_distance)
    iteration_time = Configuration::WORLD_TIMESTEP /
                     Configuration::WORLD_NUM_ITERATIONS
    @integral_error += error * iteration_time
    @integral_error = [[integral_error, -@integral_error_cap].max,
                       @integral_error_cap].min
    derivative_error = 0
    unless @previous_error.nil?
      derivative_error = (error - @previous_error) / iteration_time
    end

    p_force = @k_P * error
    i_force = @k_I * integral_error
    d_force = @k_D * derivative_error
    self.force = p_force + i_force + d_force + @static_force +
                 lookup_static_force
    @previous_error = error

    return unless @logging
    puts "#{(error * 100).round(2)}||#{force.round(2)}|"\
          "#{p_force.round(2)}|#{i_force.round(2)}|"\
          "#{d_force.round(2)}||"\
          "#{@joint.linear_tension.length.to_f.round(2)}|"\
          "#{lookup_static_force}"
  end

  def set_pid_values(proportional, integral, derivative)
    @k_P = proportional
    @k_I = integral
    @k_D = derivative
  end

  def reset_errors
    @integral_error = 0
    @previous_error = nil
  end

  def analyze_static_forces
    puts "Analyzing static forces of selected controller"
    pid_edge_id, pid_edge =
      Graph.instance.edges.find { |_, edge| edge.link == self }
    old_link = pid_edge.link
    #TODO: Give the Actuator the correct min/max distances
    pid_edge.link_type = 'actuator'
    Sketchup.active_model.active_view.invalidate
    simulation = Simulation.new
    simulation.setup
    forces = []

    step_width = 1.0 / Configuration::STATIC_FORCE_ANALYSIS_STEPS
    (0.0..1.0).step(step_width).each do |position|
      force = simulation.check_static_force(pid_edge_id, position)
      simulation.reset
      simulation.setup
      forces.push(force)
    end
    pid_edge.link_type = 'pid_controller'
    new_pid_link = Graph.instance.edges[pid_edge_id].link
    puts "Position:Force"
    forces.each_with_index do |force, idx|
      p "#{(idx * step_width).round(2)}: #{forces[idx].round(2)}"
    end
    old_link.write_parameters_to(new_pid_link)
    new_pid_link.static_forces_lookup = forces
  end

  def write_parameters_to(pid_controller)
    pid_controller.k_P = @k_P
    pid_controller.k_D = @k_D
    pid_controller.k_I = @k_I
    pid_controller.logging = @logging
    pid_controller.target_length = @target_length
    pid_controller.static_force = @static_force
    pid_controller.integral_error_cap = @integral_error_cap
  end
end
