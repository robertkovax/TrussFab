require 'src/tools/tool.rb'
require 'src/export/node_export_algorithm.rb'

# Shortens to selected elongations as much as possible
class OptimizeElongationTool < Tool
  def activate
    node_export_algorithm = NodeExportAlgorithm.instance
    node_export_algorithm.run

    selection = Sketchup.active_model.selection
    return if selection.nil? or selection.empty?

    selected_nodes = []
    selection.each do |entity|
      next if entity.nil? || entity.deleted?

      type = entity.get_attribute('attributes', :type)
      id = entity.get_attribute('attributes', :id)

      next if type.nil? || id.nil?
      next unless type.include? 'Hub'

      node = Graph.instance.nodes[id]
      raise 'Node not found.' if node.nil?
      selected_nodes.push(Graph.instance.nodes[id])
    end

    return if selected_nodes.empty?

    export_interface = node_export_algorithm.export_interface
    ElongationManager.improve_elongations(export_interface, selected_nodes, true)
  end
end
