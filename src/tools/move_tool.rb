require 'src/tools/tool.rb'
require 'src/utility/relaxation.rb'
require 'src/utility/mouse_input.rb'

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

  def deactivate(view)
    super(view)
    reset
  end

  def reset
    @start_node = nil
    @start_position = nil
    @end_position = nil
    @moving = false
  end

  def draw(view)
    return unless @moving
    view.line_stipple = LINE_STIPPLE
    view.drawing_color = 'black'
    view.draw_lines(@start_position, @end_position)
  end

  def update(view, x, y)
    @mouse_input.update_positions(
      view, x, y, point_on_plane_from_camera_normal: @start_position || nil
    )

    return unless @moving && @mouse_input.position != @end_position
    @end_position = @mouse_input.position
    view.invalidate
  end

  def onMouseMove(_flags, x, y, view)
    update(view, x, y)
  end

  def onLButtonDown(_flags, x, y, view)
    update(view, x, y)
    node = @mouse_input.snapped_object
    @moving = true
    return if node.nil?
    @start_node = node
    @start_position = @end_position = node.position
  end

  def onLButtonUp(_flags, x, y, view)
    update(view, x, y)
    return unless @moving
    snapped_node = @mouse_input.snapped_object
    snapped_node = nil if snapped_node == @start_node

    Sketchup.active_model.start_operation('move node and relax', true)
    relaxation = Relaxation.new

    end_move_position = @end_position
    unless snapped_node.nil?
      # TODO: This is not working. For me, it is not even clear
      # what should be done in this case
      relaxation.fix_node(snapped_node)
      @start_node.merge_into(snapped_node)
      end_move_position = snapped_node.position
    end

    relaxation.move_and_fix_node(@start_node, end_move_position)
    relaxation.relax
    view.invalidate
    Sketchup.active_model.commit_operation

    reset
  end
end
