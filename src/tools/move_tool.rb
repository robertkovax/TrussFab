require 'src/tools/tool.rb'
require 'src/algorithms/relaxation.rb'
require 'src/utility/mouse_input.rb'

# moves or deforms an object
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
    return if @start_node.nil?
    snapped_node = @mouse_input.snapped_object
    snapped_node = nil if snapped_node == @start_node

    Sketchup.active_model.start_operation('move structure', true)
    if is_fixed?(@start_node)
      deform snapped_node
    else
      move snapped_node
    end
    view.invalidate
    Sketchup.active_model.commit_operation

    reset
  end

  def move(snapped_node)
    @end_position = snapped_node.position unless snapped_node.nil?
    translation = @end_position - @start_node.position
    nodes = breadth_search(@start_node)
    # While moving, we don't want hub's at the same position at any time,
    # because they would be joined. Therefore we reverse the array. Then even if
    # an end position in the same structure is chosen, the start_node will be
    # moved last, and so no nodes will overlap
    nodes.reverse.each do |node|
      end_position = node.position + translation
      node.update_position(end_position)
      node.update_sketchup_object
    end
    unless snapped_node.nil? || nodes.include?(snapped_node)
      @start_node.merge_into(snapped_node)
    end
  end

  def deform(snapped_node)
    relaxation = Relaxation.new

    end_move_position = @end_position
    if snapped_node.nil?
      relaxation.move_and_fix_node(@start_node, end_move_position)
      relaxation.relax
    else
      # merging functionality
      relaxation.fix_node(snapped_node)
      end_move_position = snapped_node.position
      relaxation.move_and_fix_node(@start_node, end_move_position)
      relaxation.relax
      @start_node.merge_into(snapped_node)
    end
  end

  def is_fixed?(node)
    breadth_search(node).any? { |each| each.fixed? }
  end

  def breadth_search(node)
    visited = [node]
    queue = [node]

    until queue.empty?
      current = queue.shift
      current.adjacent_nodes.each do |adjacent|
        next if visited.include? adjacent
        queue << adjacent
        visited << adjacent
      end
    end
    visited
  end
end
