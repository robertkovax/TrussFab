class SensorTool < Tool
  def initialize(ui)
    super(ui)
    @mouse_input = MouseInput.new(snap_to_nodes: true, snap_to_edges: true)
  end

  def onMouseMove(_flags, x, y, view)
    @mouse_input.update_positions(view, x, y)
  end

  def onLButtonDown(_flags, x, y, view)
    @mouse_input.update_positions(view, x, y)
    obj = @mouse_input.snapped_object
    return if obj.nil?
    if obj.thingy.sensor?
      p "Removed sensor from #{obj.class.name} #{obj.id}"
    else
      p "Placed sensor at #{obj.class.name} #{obj.id}"
    end
    obj.thingy.toggle_sensor_state
  end
end
