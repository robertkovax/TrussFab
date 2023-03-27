require 'src/tools/link_tool.rb'

# Tool that places an actuator between two hubs or turns an existing edge into
# an actuator
class DoubleEdgeTool < LinkTool
  def initialize(ui, link_type= 'bottle_link')
    super(ui, link_type)
  end

  def activate

  end

  def onLButtonDown(flags, x, y, view)
    @mouse_input.update_positions(view, x, y)
    obj = @mouse_input.snapped_object
    if obj.is_a?(Edge)
      obj.link.marked_as_double = !obj.link.marked_as_double
      if obj.link.marked_as_double
        material = Sketchup.active_model.materials.add("marked_as_double")
        material.color = Sketchup::Color.new(1.0, 0.0, 1.0)
        material.alpha = 1.0
        obj.link.material = material
      else
        obj.link.material = Sketchup.active_model.materials['standard_material']
      end
      obj.link.recreate_children
    end

    find_soft_euler_path
  end

  def find_soft_euler_path
    graph = TubeGraph.from_graph(Graph.instance)
    Graph.instance.edges.each { |id, edge| edge.link.double_counter = 0}
    graph.find_soft_euler_path.each_cons(2) do |node_a, node_b|
      edge = Graph.instance.edges[node_a.edge_to(node_b).id]

      edge.link.double_counter = edge.link.double_counter + 1
      if edge.link.double_counter == 0
        edge.link.material = Sketchup.active_model.materials['standard_material']
      elsif edge.link.marked_as_double
        material = Sketchup.active_model.materials.add("double")
        material.color = Sketchup::Color.new(1.0, 0.75, 0.05)
        material.alpha = 1.0
        edge.link.material = material
      elsif edge.link.double_counter == 1
        material = Sketchup.active_model.materials.add("double")
        material.color = Sketchup::Color.new(1.0, 0.75, 0.05)
        material.alpha = 1.0
        edge.link.material = material
      elsif edge.link.double_counter == 2
        material = Sketchup.active_model.materials.add("double")
        material.color = Sketchup::Color.new(1.0, 0.75, 0.05)
        material.alpha = 1.0
        edge.link.material = material
      end

      edge.link.recreate_children
    end
  end



end

