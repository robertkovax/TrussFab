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

  def find_limits
    @simulation = Simulation.new
    @simulation.setup
    @simulation.breaking_force = 0 #disable breaking_force
    # Sketchup.active_model.active_view.animation = @simulation
    @simulation.update_world_headless_by(3) #settle down
    settled_distance = @edge.thingy.joint.cur_distance
    while (@edge.thingy.joint.cur_distance - settled_distance).abs < @threshold && @steps < 500
      apply_force
      @steps = @steps + 1
    end
    p @force
    p @steps
  end

  def apply_force
    @force = @force - 10
    @edge.thingy.force = @force
    @simulation.update_world_headless_by(0.2)
  end
end
