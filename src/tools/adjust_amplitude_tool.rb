require_relative 'tool.rb'

# Tool that allows users to pull a line from a node to interact with the model / gemoetry.
class AdjustAmplitudeTool < Tool
  def initialize(ui)
    super(ui)
    @mouse_input = MouseInput.new(snap_to_edges: false, snap_to_nodes: false)

    @moving = false
  end

  def onLButtonDown(_flags, x, y, view)
    position = @mouse_input.update_positions(view, x, y)

    # TODO: Don't talk to strangers coding style wise this is broken
    handles = @ui.spring_pane.path_visualization.handles

    # find closes handle
    # remember it
  end

  def onMouseMove(_flags, x, y, view)
    update(view, x, y)
    # move handle along the handle path
  end

  def onLButtonUp(_flags, x, y, view)
    # forget handle
    update(view, x, y)
  end

  def update(view, x, y)
    @mouse_input.update_positions(view, x, y, point_on_plane_from_camera_normal: @start_position || nil)

    return unless @moving && @mouse_input.position != @end_position

    @end_position = @mouse_input.position
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
