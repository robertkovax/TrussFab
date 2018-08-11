require 'src/tools/tool.rb'
require 'src/utility/mouse_input.rb'
require 'src/utility/json_import.rb'
require 'src/database/graph.rb'
require 'src/configuration/configuration.rb'
require 'src/sketchup_objects/actuator_link.rb'

# Imports an object from a JSON file
class ImportTool < Tool
  def initialize(_ui)
    super
    @mouse_input = MouseInput.new(snap_to_surfaces: true)
    @path = nil
    @angle = 0
  end

  def onKeyDown(key, _repeat, _flags, _view)
    super
    puts @angle
    if key == VK_RIGHT
      @angle -= (2.0 / 3) * Math::PI
      rotate_model
    elsif key == VK_LEFT
      @angle += (2.0 / 3) * Math::PI
      rotate_model
    end
  end

  def rotate_model
    return if @last_imported_edges.nil?
    delete_edges @last_imported_edges
    Sketchup.active_model.start_operation('rotate', true)
    if @last_graph_object.is_a?(Triangle)
      _, new_edges, animation = JsonImport.at_triangle(@path,
                                                       @last_graph_object,
                                                       angle: @angle)
    else
      _, new_edges, animation =
        JsonImport.at_position(@path, @last_position, angle: @angle)
    end
    Sketchup.active_model.commit_operation
    setup_new_edges(new_edges, animation)
    @last_imported_edges = new_edges
  end

  def activate
    BottleCounter.update_status_text
  end

  def onMouseMove(_flags, x, y, view)
    @mouse_input.update_positions(view, x, y)
  end

  def onLButtonDown(_flags, x, y, view)
    @angle = 0
    @mouse_input.update_positions(view, x, y)
    snapped_object = @mouse_input.snapped_object
    import_from_json(@path, snapped_object, @mouse_input.position)
    @ui.animation_pane.sync_hidden_status(Graph.instance.actuator_groups)
    @mouse_input.update_positions(view, x, y)
    view.invalidate
  end

  def setup_new_edges(new_edges, animation)
    new_edges.each do |edge|
      next unless edge.link.is_a?(ActuatorLink)
      if edge.link.piston_group < 0
        edge.link.piston_group = IdManager.instance.maximum_piston_group + 1
      end
      @ui.animation_pane.add_piston(edge.link.piston_group) if animation == ''
    end
    return if animation == ''
    @ui.animation_pane.add_piston_with_animation(animation)
  end

  def import_from_json(path, graph_object, position)
    Sketchup.active_model.start_operation('import from JSON', true)
    if graph_object.is_a?(Triangle)
      _, new_edges, animation = JsonImport.at_triangle(path, graph_object)
      setup_new_edges(new_edges, animation)
    elsif graph_object.nil?
      return unless Graph.instance.find_close_node(position).nil?
      old_triangles = Graph.instance.triangles.values
      new_triangles, new_edges, animation =
        JsonImport.at_position(path, position)
      if intersecting?(old_triangles, new_triangles)
        puts('New object intersects with old')
        delete_edges(new_edges)
        return
      end
      setup_new_edges(new_edges, animation)
    else
      raise NotImplementedError
    end
    @last_imported_edges = new_edges
    @last_graph_object = graph_object
    @last_position = position
    Sketchup.active_model.commit_operation
  end

  def intersecting?(old_triangles, new_triangles)
    old_triangles.each do |old_triangle|
      new_bounds = Geom::BoundingBox.new
      new_triangles.each do |new_triangle|
        new_bounds.add(new_triangle.surface.entity.bounds)
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
      oent = old_triangle.surface.entity
      next unless oent.valid?
      old_bounds = oent.bounds
      intersection = old_bounds.intersect(new_bounds)

      if intersection.valid?
        Sketchup.active_model.commit_operation
        return true
      end
    end
    puts('Add object on the ground')
    false
  end

  def delete_edges(edges)
    Sketchup.active_model.start_operation('delete edges', true)
    edges.each(&:delete)
    Sketchup.active_model.commit_operation
  end
end
