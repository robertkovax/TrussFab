require 'src/tools/tool.rb'
require 'src/utility/mouse_input.rb'
require 'src/utility/json_import.rb'

class JsonTool < Tool
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
    snapped_graph_object = @mouse_input.snapped_graph_object
    import_from_json(@path, snapped_graph_object, @mouse_input.position)
    view.invalidate
  end

  def import_from_json(path, graph_object, position=nil)
    Sketchup.active_model.start_operation('import from JSON', true)
    if graph_object.is_a?(Triangle)
      JsonImport.at_triangle(path, graph_object)
      puts 'Add object on triangle'
    elsif graph_object.nil?
      JsonImport.at_position(path, position)
      puts 'Add object on the ground'
    else
      raise "not yet implemented"
    end
    Sketchup.active_model.commit_operation
  end
end
