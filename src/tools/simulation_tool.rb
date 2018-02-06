require 'src/tools/tool.rb'
require 'src/utility/mouse_input.rb'
require 'src/simulation/simulation.rb'

class SimulationTool < Tool
  def initialize(ui)
    super(ui)
    @mouse_input = MouseInput.new(snap_to_nodes: true)
    @move_mouse_input = nil

    @node = nil
    @start_position = nil
    @end_position = nil
    @moving = false
  end

  def activate
    @simulation = Simulation.new
    @simulation.setup
    @simulation.piston_dialog
    @simulation.chart_dialog
    @simulation.open_sensor_dialog
    Sketchup.active_model.active_view.animation = @simulation
    @simulation.start
  end

  def deactivate(view)
    view.animation = nil
    @simulation.reset
    @simulation.close_piston_dialog
    @simulation.close_chart
    @simulation.close_sensor_dialog
    @simulation = nil
    super
    view.invalidate
  end

  def soft_update(view)
    return unless @moving
    @start_position = @node.position
    @end_position = @mouse_input.position
    @simulation.add_force_to_node(@node, @start_position.vector_to(@end_position))
    view.invalidate
  end

  def update(view, x, y)
    @mouse_input.update_positions(
      view, x, y, point_on_plane_from_camera_normal: @start_position || nil
    )

    soft_update(view)
  end

  def reset
    @node = nil
    @start_position = nil
    @end_position = nil
    @moving = false
  end

  def onLButtonDown(_flags, x, y, view)
    update(view, x, y)
    node = @mouse_input.snapped_object
    return if node.nil?
    @moving = true
    @node = node
    @start_position = @end_position = @mouse_input.position
  end

  def onMouseMove(_flags, x, y, view)
    update(view, x, y)
  end

  def onLButtonUp(_flags, x, y, view)
    update(view, x, y)
    return unless @moving
    @end_position = @mouse_input.position
    reset
  end

  def draw(view)
    soft_update(view)
    return if @start_position.nil? || @end_position.nil?
    view.line_stipple = '_'
    view.draw_lines(@start_position, @end_position)
  end
end
