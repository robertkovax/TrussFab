class Tool
  def initialize ui
    @ui = ui
  end

  def onKeyDown key, repeat, flags, view
    if key == 27 # ESC
      Sketchup.active_model.select_tool nil
    end
  end

  def deactivate view
    @ui.deselect_tool
  end
end