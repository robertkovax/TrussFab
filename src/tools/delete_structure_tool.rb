require 'src/tools/tool.rb'
require 'src/utility/mouse_input.rb'

# Deletes the connected component of the selected element
class DeleteStructureTool < Tool
  def initialize(_ui)
    super
    @mouse_input = MouseInput.new(snap_to_nodes: true,
                                  snap_to_edges: true,
                                  snap_to_pods: true,
                                  snap_to_covers: true)
  end

  def onLButtonDown(_flags, x, y, view)
    delete(x, y, view)
  end

  def onMouseMove(_flags, x, y, view)
    @mouse_input.update_positions(view, x, y)
  end

  private

  def delete(x, y, view)
    @mouse_input.update_positions(view, x, y)
    object = @mouse_input.snapped_object
    return if object.nil?
    Sketchup.active_model.start_operation('Delete Object', true)
    object.connected_component.each(&:delete)
    Sketchup.active_model.commit_operation
    @ui.animation_pane.sync_hidden_status(Graph.instance.actuator_groups)
    view.invalidate
  end
end
