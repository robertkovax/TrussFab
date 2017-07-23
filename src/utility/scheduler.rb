class Scheduler
  include Singelton

  DEFAULT_SCHEDULE = [0,0,0,0]
  MAX_EXPANSION = 0.15
  STEPS_PER_INTERVAL = 100

  def initialize
    @groups = {}   # group_id => (color, schedule, expansion)
    @new_group_id = 0
  end

  ### group management
  def self.next_group(group_id)
    next_group_id = ( group_id + 1 ) % @groups.size
    color, _, _ = @groups[next_group_id]
    return next_group_id, color
  end

  def self.previous_group(group_id)
    next_group_id = ( group_id - 1 ) % @groups.size
    color, _, _ = @groups[next_group_id]
    return next_group_id, color
  end

  def self.new_group
    # creates a new group with a new random color
    # and standart schedule
    color = new_color(@new_group_id)
    @groups[ @new_group_id ] = [color, DEFAULT_SCHEDULE, 0]
    @new_group_id += 1
    color
  end

  def color_for(group_id)
    color, _, _ = @groups[ group_id ]
    color
  end

  def schedule_groups(timestep)
    calculate_expansions
    set_piston_controllers
  end

  private

  def calculate_expansions
    @groups.each do |group_id, color, schedule, expansion|
      block_progress = ((timestep % STEPS_PER_INTERVAL ) / ( 1.0 * STEPS_PER_INTERVAL))
      size = schedule.size
      current_block_idx = (timestep / STEPS_PER_INTERVAL) % size 
      next_block_idx = (current_block_idx + 1) % size
      total_change = schedule[current_block_idx] - schedule[next_block_idx]
      relative_expansion = schedule[current_block_idx] - total_change * block_progress
      # puts("#{current_idx}>>>>> a: #{a}, b: #{b}")
      @groups[group_id][2] = relative_expansion * @max_expansion
    end
  end

  def set_piston_controllers
    actuators = Graph.instance.edges.values.select { |edge| edge.link_type == 'actuator' }
    unless actuators.nil?
      actuators.each do |actuator|
        _, _, expansion = @groups[actuator.group] 
        actuator.thingy.piston.controller = expansion
    end
  end

  def new_color(group_id)
    material = Sketchup.active_model.materials.add(group_id.to_s)
    material.color = [1, 1, 1]
    material.alpha = 1
    material
  end
end
