require 'src/tools/link_tool.rb'

# Tool that places an actuator between two hubs or turns an existing edge into
# an actuator
class ActuatorTool < LinkTool
  def initialize(ui, link_type= 'actuator')
    super(ui, link_type)
  end

  def activate
    selection = Sketchup.active_model.selection
    return if selection.nil? or selection.empty?

    edges = []
    selection.each do |entity|
      next if entity.nil? || entity.deleted?

      type = entity.get_attribute('attributes', :type)
      id = entity.get_attribute('attributes', :id)

      next if type.nil? || id.nil?

      if type.include? "Link"
        edge = Graph.instance.edges[id]
        edges.push(edge) if edge
      end
    end

    edges.each do |edge|
      change_link_to_physics_link Sketchup.active_model.active_view, edge
    end
  end

  def onLButtonDown(flags, x, y, view)
    @mouse_input.update_positions(view, x, y)
    obj = @mouse_input.snapped_object
    if obj.is_a?(Edge) && obj.link_type == @link_type
      change_piston_group(obj)
      @ui.animation_pane.add_piston(obj.link.piston_group)
    else
      @edge = if !obj.nil? && obj.is_a?(Edge)
                change_link_to_physics_link(view, obj)
              else
                create_new_physics_link(view, x, y)
              end
      return if @edge.nil?
      @edge.link.piston_group = IdManager.instance.maximum_piston_group
      @ui.animation_pane.add_piston(@edge.link.piston_group)
    end
    @ui.animation_pane.sync_hidden_status(Graph.instance.actuator_groups)
  end

  def change_piston_group(edge)
    max_group = Graph.instance.edges.count do |e|
      e[1].link.is_a?(ActuatorLink)
    end - 1
    if edge.link.piston_group < max_group
      edge.link.piston_group += 1
    else
      edge.link.piston_group = 0
    end
  end
end
