require 'src/tools/tool.rb'
require 'src/utility/mouse_input.rb'
require 'src/simulation/simulation.rb'
require 'src/configuration/configuration.rb'

class FindLimitsTool < Tool

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
    @threshold = 0.01
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
    return if edge.nil?
    @moving = true
    @edge = edge
    find_limits
  end

  def setup_simulation
    @simulation.setup
    @simulation.breaking_force = 0 #disable breaking_force
    @simulation.update_world_headless_by(1) #settle down
    @force = 0
  end

  def reset_simulation
    @simulation.reset
    @simulation.setup
    @simulation.breaking_force = 0
    @simulation.update_world_headless_by(1) #settle down again
    @simulation.breaking_force = Configuration::JOINT_BREAKING_FORCE
    @force = -Configuration::JOINT_BREAKING_FORCE
  end

  def find_limits
    @simulation = Simulation.new
    setup_simulation
    settled_distance = @edge.thingy.joint.cur_distance
    #Find min force until it moves
    while (@edge.thingy.joint.cur_distance - settled_distance).abs < @threshold && @steps < 500
      apply_force_increasing
      @steps += 1
    end
    @min_force = @force

    #Find max force before it breaks
    reset_simulation
    @new_force = 0

    broke_previously = false
    for i in 0..50
      reset_simulation
      apply_force_binary_search(!broke_previously)
      broke_previously = @simulation.broken?
    end
    @max_force = @force

    p @min_force
    p @max_force
  end

  def apply_force_increasing
    @force -= 10
    @edge.thingy.force = @force
    @simulation.update_world_headless_by(0.2)
  end

  def apply_force_binary_search(increasing)
    if increasing
      @new_force = (@new_force + @force) / 2
    else
      @force = (@new_force + @force) / 2
    end
    @edge.thingy.force = (@new_force + @force) / 2
    @simulation.update_world_headless_by(0.1)
  end
end
