require 'src/tools/tool.rb'
require 'src/utility/mouse_input.rb'

# Deletes the connected component of the selected element
class DeleteStructureTool < Tool

  def activate
    selection = Sketchup.active_model.selection
    p selection
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
end
