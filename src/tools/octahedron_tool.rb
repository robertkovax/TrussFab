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
    Sketchup.active_model.start_operation('add octa on ground', true)
    # TODO: add creation by geometry
    puts 'Add octahedron on the ground'
    JsonImport.import(Configuration::OCTAHEDRON, @mouse_input.position)
    view.invalidate
    Sketchup.active_model.commit_operation
  end
end
