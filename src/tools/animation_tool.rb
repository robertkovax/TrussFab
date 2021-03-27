require_relative 'tool.rb'

# Tool that allows users to pull a line from a node to interact with the model / gemoetry.
class AnimationTool < Tool
  def initialize(ui)
    super(ui)
    @mouse_input = MouseInput.new(snap_to_edges: false, snap_to_nodes: false)

    @mouse_down = false
  end

  def onLButtonDown(_flags, x, y, view)
    @mouse_down = true
    position = @mouse_input.update_positions(view, x, y)

    normal = view.camera.direction
    eye = view.camera.eye
    res = Sketchup.active_model.raytest(view.pickray(x,y))
    face = res ? res[1][-1] : nil
    @ui.spring_pane.toggle_animation_for_face(face)
  end

  def onMouseMove(_flags, x, y, view)
    @mouse_input.update_positions(view, x, y)
  end
end
