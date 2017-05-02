require 'src/tools/tool.rb'
require 'src/utility/mouse_input.rb'
require 'src/utility/json_import.rb'
require 'src/utility/tetrahedron.rb'

class TetrahedronTool < Tool
  def initialize(ui = nil)
    super
    @mouse_input = MouseInput.new(snap_to_surfaces: true)
  end

  def onMouseMove(_flags, x, y, view)
    @mouse_input.update_positions(view, x, y)
  end

  def onLButtonDown(_flags, x, y, view)
    @mouse_input.update_positions(view, x, y)
    triangle = @mouse_input.snapped_graph_obj
    Sketchup.active_model.start_operation('create tetra', true)
    puts 'Create tetrahedron'
    # TODO: change model definition to default (settings file)
    Tetrahedron.build(@mouse_input.position, ModelStorage.instance.models['hard'].longest_model, triangle)
    view.invalidate
    Sketchup.active_model.commit_operation
  end
end
