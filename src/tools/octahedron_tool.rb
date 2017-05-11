require 'src/tools/tool.rb'

class OctahedronTool < Tool
  def initialize(ui)
    super
    @mouse_input = MouseInput.new(snap_to_surfaces: true)
  end

  def onMouseMove(_flags, x, y, view)
    @mouse_input.update_positions(view, x, y)
  end

  def onLButtonDown(_flags, x, y, view)
    @mouse_input.update_positions(view, x, y)
    triangle = @mouse_input.snapped_graph_object
    return if triangle.nil?
    Sketchup.active_model.start_operation('add octa on ground', true)
    # TODO: add creation by geometry
    puts 'Add octahedron on the ground'
    JsonImport.import_at_triangle(Configuration::OCTAHEDRON, triangle)
    view.invalidate
    Sketchup.active_model.commit_operation
  end
end
