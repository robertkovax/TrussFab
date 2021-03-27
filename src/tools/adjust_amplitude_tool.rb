require_relative 'tool.rb'

# Tool that allows users to pull a line from a node to interact with the model / gemoetry.
class AdjustAmplitudeTool < Tool
  def initialize(ui)
    super(ui)
    @mouse_input = MouseInput.new(snap_to_edges: false, snap_to_nodes: false)

    @mouse_down = false
  end

  def onLButtonDown(_flags, x, y, view)

    # Detect widgets
    position = @mouse_input.update_positions(view, x, y)
    closest_widget = @ui.spring_pane.widgets.values.flatten.min_by { |widget| position.distance(widget.position)}
    puts closest_widget.position.distance(position)
    if closest_widget.position.distance(position) < 10.cm
      closest_widget.cycle!
      return
    end


    handles = @ui.spring_pane.trace_visualization.handles.values.flatten
    @selected_handle = handles.min_by { |handle| position.distance(handle.position)}
    puts "Selected #{@selected_handle}"
    distance_to_handle = @selected_handle.position.distance(position)
    puts "Distance to selected handle: #{distance_to_handle}"
    return if distance_to_handle > 20.cm

    @mouse_down = true

    @handle_start_position = position
  end

  def onMouseMove(_flags, x, y, view)
    update(view, x, y)
    # move handle along the handle path
  end

  def onLButtonUp(_flags, x, y, view)
    return unless @mouse_down
    @mouse_down = false
    update(view, x, y)

    TrussFab.get_spring_pane.notify_model_changed amplitude_tweak: true
  end

  def update(view, x, y)
    return unless @mouse_down

    @mouse_input.update_positions(view, x, y, point_on_plane_from_camera_normal: @selected_handle.position)


    @end_position = @mouse_input.position
    handle_position =
      Geometry::find_closest_point_on_curve(@mouse_input.position, @selected_handle.movement_curve)
    @selected_handle.update_position(handle_position, move_partner: true)
    view.invalidate
  end

  def reset
    @start_node = nil
    @start_position = nil
    @end_position = nil
    @moving = false
  end

  def draw(view)
    return unless @moving

    view.line_stipple = ''
    view.line_width = 7
    view.drawing_color = 'black'
    view.draw_lines(@start_position, @end_position)
  end
end
