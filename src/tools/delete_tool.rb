require 'src/tools/tool.rb'
require 'src/utility/mouse_input.rb'

class DeleteTool < Tool
  def initialize(ui)
    super
    @mouse_input = MouseInput.new(snap_to_nodes: true, snap_to_edges: true)
  end

  def onLButtonDown(_flags, x, y, view)
    @clicking = true
    @initial_click_position = [x, y]
    delete(x, y, view)
  end

  def onMouseMove(_flags, x, y, view)
    return unless @clicking
    unless @deleting
      distance_moved = Math.sqrt((@initial_click_position[0] - x)**2 + (@initial_click_position[1] - y)**2)
      @deleting = distance_moved > 10
    end
    delete(x, y, view) if @deleting
  end

  def onLButtonUp(_flags, _x, _y, _view)
    @clicking = false
    @deleting = false
  end

  private

  def delete(x, y, view)
    @mouse_input.update_positions(view, x, y)
    graph_obj = @mouse_input.snapped_graph_object
    return if graph_obj.nil?
    delete_node(graph_obj) if graph_obj.is_a?(Node)
    delete_edge(graph_obj) if graph_obj.is_a?(Edge)
    view.invalidate
  end

  def delete_node(node)
    Sketchup.active_model.start_operation('Delete hub and adjacent edges', true)
    node.delete
    Sketchup.active_model.commit_operation
  end

  def delete_edge(edge)
    Sketchup.active_model.start_operation('Delete edge', true)
    edge.delete
    Sketchup.active_model.commit_operation
  end
end
