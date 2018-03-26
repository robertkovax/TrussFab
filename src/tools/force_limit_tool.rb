require 'src/tools/tool.rb'
require 'src/utility/mouse_input.rb'
require 'src/simulation/simulation.rb'
require 'src/configuration/configuration.rb'

class ForceLimitTool < Tool

  def initialize(ui)
    super(ui)
    @mouse_input = MouseInput.new(snap_to_edges: true)
    @move_mouse_input = nil

    @moving = false
    @force = 0
    @previous_force = 0
    @min_force = 0
    @max_force = 0
    @edge = nil
    @threshold = 0.02
    @piston_position = 0
    @steps = 0
  end

  def activate
  end

  def deactivate(view)
    view.animation = nil
    @simulation.reset unless @simulation.nil?
    @simulation = nil
    super
    @steps = @force = @previous_force = @min_force = @max_force = 0
    view.invalidate
  end

  def update(view, x, y)
    @mouse_input.update_positions(
      view, x, y, point_on_plane_from_camera_normal: @start_position || nil
    )
  end

  def onLButtonDown(_flags, x, y, view)
    update(view, x, y)
    edge = @mouse_input.snapped_object
    if edge.nil? || !edge.thingy.is_a?(GenericLink)
      p 'Edge is invalid. Should be a GenericLink'
      return
    end

    @moving = true
    @edge = edge
    find_limits
  end

  def setup_simulation
    @simulation.setup
    @simulation.breaking_force = 0 #disable breaking_force
    @simulation.update_world_headless_by(5) #settle down
    @force = 0
  end

  def reset_simulation
    @simulation.reset
    @simulation.setup
    @simulation.breaking_force = 0
    @simulation.update_world_headless_by(5) #settle down again
    @simulation.breaking_force = Configuration::JOINT_BREAKING_FORCE
  end

  def find_limits
    @simulation = Simulation.new
    setup_simulation
    settled_distance = @edge.thingy.joint.cur_distance
    @piston_position = settled_distance
    #should we apply positive or negative force?
    positive_direction = settled_distance < @edge.thingy.default_length
    #Find min force until it moves
    while (@piston_position - settled_distance).abs < @threshold && @steps < 5000
      apply_force_increasing(positive_direction)
      @steps += 1
    end
    @min_force = @force

    #Find max force before it breaks
    reset_simulation
    @new_force = 0
    @force = Configuration::JOINT_BREAKING_FORCE
    @force *= positive_direction ? 1 : -1

    broke_previously = false
    for i in 0..50
      break if @force == @new_force
      reset_simulation
      apply_force_binary_search(!broke_previously, i == 0)
      broke_previously = @simulation.broken?
    end
    @max_force = @force

    p "Minimum Visual Actuation Force: #{@min_force} N"
    p "Maximum Force Before Breaking: #{@max_force} N"
    @simulation.reset
    @simulation = nil
  end

  def apply_force_increasing(positive_direction)
    if positive_direction
      @force += 10
    else
      @force -= 10
    end
    @edge.thingy.force = @force
    @simulation.update_world_headless_by(1)
    @piston_position = @edge.thingy.joint.cur_distance
  end

  def apply_force_binary_search(increasing, first)
    unless first
      if increasing
        @new_force = (@new_force + @force) / 2.0
      else
        @force = (@new_force + @force) / 2.0
      end
    end
    @edge.thingy.force = (@new_force + @force) / 2.0
    @simulation.update_world_headless_by(0.2)
  end
end
