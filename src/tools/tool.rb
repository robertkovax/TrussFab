# superclass for all tools
class Tool
  def initialize(ui)
    @ui = ui
  end

  def onKeyDown(key, _repeat, _flags, _view)
    Sketchup.active_model.select_tool(nil) if key == 27 # ESC
  end

  def onRButtonDown(_flags, _x, _y, _view)
    Sketchup.active_model.select_tool(nil)
  end

  def deactivate(_view)
    @mouse_input.soft_reset unless @mouse_input.nil?
    @ui.deselect_tool
  end
end
