require 'src/tools/tool.rb'
require 'src/utility/mouse_input.rb'
require 'src/simulation/simulation.rb'

class SimulationTool < Tool
  def initialize(ui)
    super(ui)
    @mouse_input = MouseInput.new(snap_to_nodes: true, snap_to_edges: true, should_highlight: false)
    @move_mouse_input = nil

    @node = nil
    @start_position = nil
    @end_position = nil
    @moving = false
    @force = nil
  end

  def activate
    @simulation = Simulation.new
    @simulation.setup
    @simulation.piston_dialog
    @simulation.chart_dialog
    @simulation.open_sensor_dialog
    @simulation.open_automatic_movement_dialog
    Sketchup.active_model.active_view.animation = @simulation
    @simulation.start
  end

  def deactivate(view)
    view.animation = nil
    @simulation.reset
    @simulation.close_piston_dialog
    @simulation.close_chart
    @simulation.close_sensor_dialog
    @simulation.close_automatic_movement_dialog
    @simulation = nil
    super
    view.invalidate
  end

  def apply_force(view)
    return unless @moving
    @start_position = @node.thingy.body.get_position(1)
    @end_position = @mouse_input.position
    force = @start_position.vector_to(@end_position)
    force.length *= Configuration::DRAG_FACTOR unless force.length == 0
    @simulation.add_force_to_node(@node, force)
    view.invalidate
  end

  def update(view, x, y)
    @mouse_input.update_positions(
      view, x, y, point_on_plane_from_camera_normal: @start_position || nil
    )
  end

  def reset
    @node = nil
    @start_position = nil
    @end_position = nil
    @moving = false
    @force.text = ''
    @force = nil
  end

  def onLButtonDown(_flags, x, y, view)
    update(view, x, y)
    obj = @mouse_input.snapped_object
    return if obj.nil?
    if obj.is_a?(Node)
      @moving = true
      @node = obj
      @start_position = @end_position = @mouse_input.position
    elsif obj.thingy.is_a?(ActuatorLink)
      @simulation.toggle_piston_group(obj)
    end
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
    apply_force(view)
    return if @start_position.nil? || @end_position.nil?
    view.line_stipple = '_'
    view.draw_lines(@start_position, @end_position)
    force_value = (@start_position.vector_to(@end_position).length * Configuration::DRAG_FACTOR).round(1).to_s
    point = Geometry.midpoint(@start_position, @end_position)
    if @force.nil?
      @force = Sketchup.active_model.entities.add_text(force_value, point)
    else
      @force.text = force_value
      @force.point = point
    end
  end

end
