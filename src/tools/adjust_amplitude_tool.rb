require_relative 'tool.rb'

# Tool that allows users to pull a line from a node to interact with the model / gemoetry.
class AdjustAmplitudeTool < Tool
  def initialize(ui)
    super(ui)
    @mouse_input = MouseInput.new(snap_to_edges: false, snap_to_nodes: false)

    @mouse_down = false
  end

  def onLButtonDown(_flags, x, y, view)
    @mouse_down = true
    position = @mouse_input.update_positions(view, x, y)

    handles = @ui.spring_pane.trace_visualization.handles
    @selected_handle = handles.min_by { |handle| position.distance(handle.position)}
    puts "Selected #{@selected_handle}"
    @handle_start_position = position
  end

  def onMouseMove(_flags, x, y, view)
    update(view, x, y)
    # move handle along the handle path
  end

  def onLButtonUp(_flags, x, y, view)
    @mouse_down = false
    # forget handle
    update(view, x, y)
  end

  def update(view, x, y)
    @mouse_input.update_positions(view, x, y, point_on_plane_from_camera_normal: @start_position || nil)

    return unless @mouse_down

    @end_position = @mouse_input.position
    handle_position =
      find_closest_on_curve(@mouse_input.position, @selected_handle.movement_curve)
    @selected_handle.update_position(handle_position)
    @selected_handle.partner_handle.update_position(handle_position)
    # TODO: Update partner handle
    view.invalidate
  end

  # TODO: Might want to live inside the geometry module for later optimization
  def find_closest_on_curve(point, curve)
    closest_distance = Float::INFINITY
    closest_point = nil
    curve.each_cons(2) do |segment_start, segment_end|
      dist = Geometry::dist_point_to_segment(point, [segment_start, segment_end])
      if dist < closest_distance
        closest_distance = dist
        closest_point =
          Geometry::closest_point_on_segment(point, [segment_start , segment_end])
      end
    end
    closest_point
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
