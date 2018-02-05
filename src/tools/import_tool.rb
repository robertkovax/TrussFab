require 'src/tools/tool.rb'
require 'src/utility/mouse_input.rb'
require 'src/utility/json_import.rb'
require 'src/database/graph.rb'
require 'src/configuration/configuration.rb'

class ImportTool < Tool
  def initialize(ui = nil)
    super
    @mouse_input = MouseInput.new(snap_to_surfaces: true)
    @path = nil
  end

  def onMouseMove(_flags, x, y, view)
    @mouse_input.update_positions(view, x, y)
  end

  def onLButtonDown(_flags, x, y, view)
    @mouse_input.update_positions(view, x, y)
    snapped_object = @mouse_input.snapped_object
    import_from_json(@path, snapped_object, @mouse_input.position)
    @mouse_input.update_positions(view, x, y)
    view.invalidate
  end

  def import_from_json(path, graph_object, position)
    Sketchup.active_model.start_operation('import from JSON', true)
    if graph_object.is_a?(Triangle)
      JsonImport.at_triangle(path, graph_object)
    elsif graph_object.nil?
      return unless Graph.instance.find_close_node(position).nil?
      old_triangles = Graph.instance.surfaces.values
      new_triangles, new_edges = JsonImport.at_position(path, position)
      if intersecting?(old_triangles, new_triangles)
        puts('New object intersects with old')
        delete_edges(new_edges)
      end
    else
      raise NotImplementedError
    end
    Sketchup.active_model.commit_operation
  end

  def intersecting?(old_triangles, new_triangles)
    old_triangles.each do |old_triangle|
      new_bounds = Geom::BoundingBox.new
      new_triangles.each do |new_triangle|
        new_bounds.add(new_triangle.thingy.entity.bounds)
      end
      # expand the bounding box along the diagonal of the already existing one
      left_front_bottom = new_bounds.corner(0)
      right_back_top = new_bounds.corner(7)
      diagonal = Geom::Vector3d.new(left_front_bottom, right_back_top)
      new_bounds.add(right_back_top.offset(
                       diagonal,
                       Configuration::INTERSECTION_OFFSET
      ))
      new_bounds.add(left_front_bottom.offset(
                       diagonal.reverse,
                       Configuration::INTERSECTION_OFFSET
      ))
      oent = old_triangle.thingy.entity
      if oent.valid?
        old_bounds = oent.bounds
        intersection = old_bounds.intersect(new_bounds)
        return true if intersection.valid?
      end
    end
    puts('Add object on the ground')
    false
  end

  def delete_edges(edges)
    edges.each(&:delete)
  end
end
