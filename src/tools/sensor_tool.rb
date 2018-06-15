# Places a sensor on an edge or node
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

    sketchup_object = if obj.is_a?(Node)
                        obj.hub
                      elsif obj.is_a?(Edge)
                        obj.link
                      end

    if sketchup_object.sensor?
      p "Removed sensor from #{obj.class.name} #{obj.id}"
    else
      p "Placed sensor at #{obj.class.name} #{obj.id}"
    end
    sketchup_object.toggle_sensor_state
  end
end
