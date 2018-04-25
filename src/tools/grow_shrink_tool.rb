require 'src/tools/tool.rb'
require 'src/algorithms/relaxation.rb'

# increases or decreases the size of an edge
class GrowShrinkTool < Tool
  def initialize(ui)
    super(ui)
    @mouse_input = MouseInput.new(snap_to_edges: true)
  end

  def onMouseMove(_flags, x, y, view)
    @mouse_input.update_positions(view, x, y)
  end

  def alter_edge(_edge, _relaxation)
    raise NotImplementedError
  end

  def onLButtonDown(_flags, x, y, view)
    @mouse_input.update_positions(view, x, y)
    edge = @mouse_input.snapped_object
    return if edge.nil?
    Sketchup.active_model.start_operation('grow/shrink edge and relax', true)
    relaxation = Relaxation.new
    alter_edge(edge, relaxation)
    relaxation.relax
    view.invalidate
    Sketchup.active_model.commit_operation
  end
end

# increases the size of an edge
class GrowTool < GrowShrinkTool
  def alter_edge(edge, relaxation)
    relaxation.stretch(edge)
  end
end

# decreases the size of an endge
class ShrinkTool < GrowShrinkTool
  def alter_edge(edge, relaxation)
    relaxation.shrink(edge)
  end
end
