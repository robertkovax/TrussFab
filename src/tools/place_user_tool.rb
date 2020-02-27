
# Places a user into the geometry i.e. someone who is injecting force into the system. This tool simulates the system
# and opens a panel that shows information and the possibility to change parameters of the springs.
class PlaceUserTool < Tool

  def initialize(ui)
    super(ui)
    @mouse_input = MouseInput.new(snap_to_edges: true, snap_to_nodes: true)
  end

  def onLButtonDown(_flags, x, y, view)
    @mouse_input.update_positions(view, x, y)
    obj = @mouse_input.snapped_object
    if !obj.nil? && obj.is_a?(Node)
      obj.hub.toggle_attached_user
    end
  end

end
