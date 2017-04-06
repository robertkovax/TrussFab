require ProjectHelper.tool_directory + '/tool.rb'
require ProjectHelper.utility_directory + '/mouse_input.rb'
require ProjectHelper.utility_directory + '/json_import.rb'


class TetrahedronTool < Tool
  def initialize ui = nil
    super
    @mouse_input = MouseInput.new snap_to_surfaces: true
  end

  def activate
  end

  def onMouseMove flags, x, y, view
    @mouse_input.update_positions view, x, y
  end

  def onLButtonDown flags, x, y, view
    surface = nil
    Sketchup.active_model.start_operation "add tetra on ground", true
    # TODO add creation by geometry
    puts "Add tetrahedron on the ground"
    JsonImport.import Configuration::TETRAHEDRON, @mouse_input.position
    view.invalidate
    Sketchup.active_model.commit_operation
  end
end