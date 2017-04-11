require ProjectHelper.tool_directory + '/tool.rb'
require ProjectHelper.utility_directory + '/mouse_input.rb'
require ProjectHelper.utility_directory + '/json_import.rb'
require ProjectHelper.utility_directory + '/tetrahedron.rb'

class TetrahedronTool < Tool
  def initialize ui = nil
    super
    @mouse_input = MouseInput.new snap_to_surfaces: true
  end

  def onMouseMove flags, x, y, view
    @mouse_input.update_positions view, x, y
  end

  def onLButtonDown flags, x, y, view
    @mouse_input.update_positions view, x, y
    surface = @mouse_input.snapped_thingy
    Sketchup.active_model.start_operation "create tetra", true
    puts "Create tetrahedron"
    # TODO change model definition to default (settings file)
    Tetrahedron.build @mouse_input.position, ModelStorage.instance.models['hard'].longest_model, surface
    view.invalidate
    Sketchup.active_model.commit_operation
  end
end