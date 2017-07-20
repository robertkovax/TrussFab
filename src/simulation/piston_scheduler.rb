class PistonScheduler
  def initialize
    @piston_expansion = 0
    @max_expansion = 0.15


    @schedules = {}
    @schedule_a = ['a', [ 1,  1, -1, -1, ]]
    @schedule_b = ['b', [ 1, -1, -1,  1, ]]

    @schedule_c = ['c', [-1, -1,  1,  1, ]]
    @schedule_d = ['d', [-1,  1,  1, -1, ]]
    # @schedule_a = ['a', [ 1,  1,  1, -1, -1, -1, -1]]
    # @schedule_b = ['b', [ 1,  1, -1, -1, -1,  1,  1]]

    # @schedule_c = ['c', [-1, -1, -1, -1,  1,  1,  1]]
    # @schedule_d = ['d', [-1,  1,  1,  1,  1, -1, -1]]
    @piston_step = 100
  end

  def actuators
    Graph.instance.edges.values.select { |edge| edge.link_type == 'actuator' }
  end

  def update_schedule(schedule)

  end

  def schedule_pistons
    unless actuators.empty?
      size = @schedule_a[1].size
      current_idx = (@piston_expansion / @piston_step) % size
      next_idx = (@piston_expansion / @piston_step + 1) % size
      step_progress = ((@piston_expansion % @piston_step )/ (1.0 * @piston_step))
      [@schedule_a, @schedule_b, @schedule_c, @schedule_d].each do |schedule|
        dist = schedule[1][current_idx] - schedule[1][next_idx]
        absoulute = schedule[1][current_idx] - dist * step_progress
        # puts("#{current_idx}>>>>> a: #{a}, b: #{b}")
        schedule[0] = absoulute * @max_expansion
      end
      actuators.each do |actuator|
        case actuator.thingy.piston_group
          when 'a' then actuator.thingy.piston.controller = @schedule_a[0]
          when 'b' then actuator.thingy.piston.controller = @schedule_b[0]
          when 'c' then actuator.thingy.piston.controller = @schedule_c[0]
          when 'd' then actuator.thingy.piston.controller = @schedule_d[0]
        end
      end
      @piston_expansion = @piston_expansion + 1
    end
  end
end