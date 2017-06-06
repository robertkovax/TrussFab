require 'src/tools/tool.rb'
require 'src/utility/relaxation.rb'

class MoveTool < Tool
  LINE_STIPPLE = '_'.freeze

  def initialize(ui)
    super(ui)
    @mouse_input = MouseInput.new(snap_to_nodes: true)
    @move_mouse_input = nil

    @start_node = nil
    @start_position = nil

    @end_position = nil

    @moving = false
  end

  def reset
    @move_mouse_input = nil
    @start_node = nil
    @start_position = nil
    @end_position = nil
  end

  def draw(view)
    if @moving
      view.line_stipple = LINE_STIPPLE
      view.drawing_color = 'black'
      view.draw_lines(@start_position, @end_position)
    end
  end

  def update(view, x, y)
    if @moving
      @move_mouse_input.update_positions(view, x, y)
      if @move_mouse_input.position != @end_position
        @end_position = @move_mouse_input.position
        view.invalidate
      end
    else
      @mouse_input.update_positions(view, x, y)
    end
  end

  def onMouseMove(_flags, x, y, view)
    update(view, x, y)
  end

  def onLButtonDown(_flags, x, y, view)
    update(view, x, y)
    node = @mouse_input.snapped_graph_object
    @moving = true
    return if node.nil?
    @start_node = node
    @start_position = @end_position = node.position
    @move_mouse_input = MouseInput.new
  end

  def onLButtonUp(_flags, x, y, view)
    update(view, x, y)
    return unless @moving
    Sketchup.active_model.start_operation('move node and relax', true)
    Relaxation.new
      .move_node(@start_node, @end_position)
      .relax
    reset
    view.invalidate
    @moving = false
    Sketchup.active_model.commit_operation
  end
end
