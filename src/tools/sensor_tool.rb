class SensorTool < Tool
  def initialize(ui)
    super(ui)
    @mouse_input = MouseInput.new(snap_to_nodes: true)
  end

  def onMouseMove(_flags, x, y, view)
    @mouse_input.update_positions(view, x, y)
  end

  def onLButtonDown(_flags, x, y, view)
    @mouse_input.update_positions(view, x, y)
    hub = @mouse_input.snapped_object
    return if hub.nil?
    p "Placed sensor at Hub #{hub.id}"
    hub.thingy.toggle_sensor_state
  end
end
