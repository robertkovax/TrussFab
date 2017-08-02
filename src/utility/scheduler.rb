require 'singleton'

class Scheduler
  include Singleton

  DEFAULT_SCHEDULE = [0, 1, 0, -1]
  MAX_EXPANSION = 0.5
  STEPS_PER_INTERVAL = 100

  attr_reader :groups


  def initialize
    srand 234
    # group_id => (color, schedule, expansion)
    @groups = {}
    @new_group_id = 0
    var = 0
    new_group([-1, -1, -1, -1, -1, var, var, var, var, var])
    new_group([  var, -1, -1, -1, -1, -1,  var,  var,  var,  var])
    new_group([  var,  var, -1, -1, -1, -1, -1,  var,  var,  var])
    new_group([  var,  var,  var, -1, -1, -1, -1, -1,  var,  var])
    new_group([  var,  var,  var,  var, -1, -1, -1, -1, -1,  var])
    new_group([  var,  var,  var,  var,  var, -1, -1, -1, -1, -1])
    new_group([ -1,  var,  var,  var,  var,  var, -1, -1, -1, -1])
    new_group([ -1, -1,  var,  var,  var,  var,  var, -1, -1, -1])
    new_group([ -1, -1, -1,  var,  var,  var,  var,  var, -1, -1])
    new_group([ -1, -1, -1, -1,  var,  var,  var,  var,  var, -1])
  end

  ### group management
  def next_group(group_id)
    next_group_id = ( group_id + 1 ) % @groups.size
    color, _, _ = @groups[next_group_id]
    return next_group_id, color
  end

  def previous_group(group_id)
    next_group_id = ( group_id - 1 ) % @groups.size
    color, _, _ = @groups[next_group_id]
    return next_group_id, color
  end

  def new_group(schedule=nil)
    schedule = DEFAULT_SCHEDULE if schedule.nil?
    color = new_color(@new_group_id)
    initial_expansion = schedule.size > 0 ? schedule[0] * MAX_EXPANSION : 0
    @groups[ @new_group_id ] = [color, schedule, initial_expansion]
    @new_group_id += 1
    color
  end

  def alter(group_id, idx, new_value)
    return unless @groups.keys.include?(group_id)
    schedule = @groups[group_id][1]
    return unless idx < schedule.size
    schedule[idx] = new_value
  end

  def color_for(group_id)
    color, _, _ = @groups[ group_id ]
    color
  end

  def schedule_groups(timestep, static_state=nil)
    unless static_state.nil?
      timestep = static_state * STEPS_PER_INTERVAL
    end
    calculate_expansions(timestep)
    set_piston_controllers
  end

  private

  def calculate_expansions(timestep)
    @groups.each do |group_id, (color, schedule, expansion)|
      block_progress = ((timestep % STEPS_PER_INTERVAL ) / ( 1.0 * STEPS_PER_INTERVAL))
      size = schedule.size
      current_block_idx = (timestep / STEPS_PER_INTERVAL) % size 
      next_block_idx = (current_block_idx + 1) % size
      total_change = schedule[current_block_idx] - schedule[next_block_idx]
      relative_expansion = schedule[current_block_idx] - total_change * block_progress
      @groups[group_id][2] = relative_expansion * MAX_EXPANSION
    end
  end

  def set_piston_controllers
    actuator_edges = Graph.instance.edges.values.select { |edge| edge.link_type == 'actuator' }
    unless actuator_edges.nil?
      actuator_edges.each do |edge|
        actuator = edge.thingy
        _, _, expansion = @groups[actuator.piston_group] 
        actuator.piston.controller = expansion
      end
    end
  end

  def new_color(group_id)
    material = Sketchup.active_model.materials.add(group_id.to_s)
    material.color = [rand, rand, rand]
    material.alpha = 1
    material
  end
end
