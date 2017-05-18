require 'src/tools/tool.rb'
require 'src/utility/mouse_input.rb'
require 'src/utility/json_import.rb'
require 'src/database/graph.rb'

class ImportTool < Tool
  def initialize(ui = nil)
    super
    @mouse_input = MouseInput.new(snap_to_surfaces: true)
    @path = nil
    @new_allowed = false
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

  def onKeyDown(key, repeat, flags, view)
    @new_allowed = true if key == VK_SHIFT
  end

  def onKeyUp(key, repeat, flags, view)
    @new_allowed = false if key == VK_SHIFT
  end

  def import_from_json(path, graph_object, position=nil)
    Sketchup.active_model.start_operation('import from JSON', true)
    if graph_object.is_a?(Triangle)
      JsonImport.at_triangle(path, graph_object)
    elsif graph_object.nil?
      if Graph.instance.empty? || @new_allowed
        JsonImport.at_position(path, position)
        puts 'Add object on the ground'
      else
        puts 'We prevent objects from being created at random positions due  
              to usablity reasons. Press and hold "shift" to do it anyways'
      end
    else
      raise NotImplementedError
    end
    Sketchup.active_model.commit_operation
  end
end
