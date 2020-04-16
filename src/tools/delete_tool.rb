require 'src/tools/tool.rb'
require 'src/utility/mouse_input.rb'

# Deletes objects (like a brush)
class DeleteTool < Tool
  def initialize(_ui)
    super
    @mouse_input = MouseInput.new(snap_to_nodes: true,
                                  snap_to_edges: true,
                                  snap_to_pods: true,
                                  snap_to_covers: true)
  end

  def onLButtonDown(_flags, x, y, view)
    @clicking = true
    @initial_click_position = [x, y]
    delete(x, y, view)
  end

  def onMouseMove(_flags, x, y, view)
    @mouse_input.update_positions(view, x, y)
    return unless @clicking
    unless @deleting
      distance_moved = Math.sqrt((@initial_click_position[0] - x)**2 +
                                 (@initial_click_position[1] - y)**2)
      @deleting = distance_moved > 10
    end
    delete(x, y, view) if @deleting
  end

  def onLButtonUp(_flags, _x, _y, _view)
    @clicking = false
    @deleting = false
  end

  def activate
    selection = Sketchup.active_model.selection
    return if selection.nil? or selection.empty?

    deleted_objects = []
    selection.each do |entity|
      next if entity.nil? || entity.deleted?

      type = entity.get_attribute('attributes', :type)
      id = entity.get_attribute('attributes', :id)

      next if type.nil? || id.nil?

      if type.include? "Link" or type.include? "PidController"
        edge = Graph.instance.edges[id]
        deleted_objects.push(edge) if edge
      end

      if type.include? "Hub"
        node = Graph.instance.nodes[id]
        deleted_objects.push(node) if node
      end
    end

    deleted_objects.each(&:delete)

    @ui.animation_pane.sync_hidden_status(Graph.instance.actuator_groups)
  end

  private

  def delete(x, y, view)
    @mouse_input.update_positions(view, x, y)
    object = @mouse_input.snapped_object
    return if object.nil?
    Sketchup.active_model.start_operation('Delete Object', true)
    object.delete
    Sketchup.active_model.commit_operation
    @ui.animation_pane.sync_hidden_status(Graph.instance.actuator_groups)
    # Update springs and mounted users to changed geometry (e.g. a spring is deleted)
    @ui.spring_pane.update_springs
    @ui.spring_pane.update_mounted_users
    view.invalidate
  end
end
