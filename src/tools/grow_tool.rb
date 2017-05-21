require 'src/tools/tool.rb'
require 'src/utility/relaxation.rb'

class GrowTool < Tool
  def initialize(ui)
    puts 'super'
    super(ui)
    puts 'mouse'
    @mouse_input = MouseInput.new(snap_to_edges: true)
    puts 'relax'
    @relaxation = Relaxation.new
    puts 'finished'
  end

  def onMouseMove(_flags, x, y, view)
    @mouse_input.update_positions(view, x, y)
  end

  def onLButtonDown(_flags, x, y, view)
    @mouse_input.update_positions(view, x, y)
    edge = @mouse_input.snapped_graph_object
    return if edge.nil?
    Sketchup.active_model.start_operation('grow edge and relax', true)
    @relaxation.stretch(edge)
    puts 'after stretch'
    @relaxation.relax
    puts 'after relax'
    view.invalidate
    Sketchup.active_model.commit_operation
  end
end