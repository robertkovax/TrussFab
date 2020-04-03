# Places a user into the geometry i.e. someone who is injecting force into the system. This tool simulates the system
# and opens a panel that shows information and the possibility to change parameters of the springs.
class PlaceUserTool < Tool

  def initialize(ui)
    super(ui)
    @mouse_input = MouseInput.new(snap_to_nodes: true)
    @hub = nil
  end

  def onLButtonDown(_flags, x, y, view)
    @mouse_input.update_positions(view, x, y)
    obj = @mouse_input.snapped_object
    if !obj.nil? && obj.is_a?(Node)
      @hub = obj.hub
      # TODO remove this default force value here
      possible_names = ModelStorage.instance.possible_attachable_user_names
      if @hub.is_user_attached
        current_name = @hub.user_indicator_name
        puts current_name
        current_index = possible_names.find_index current_name
        puts current_index
        if current_index == possible_names.length - 1
          @hub.remove_user
        else
          @hub.attach_user(100, name: possible_names[current_index + 1])
        end
      else
        @hub.attach_user(100, name: possible_names[0])
      end
      @ui.spring_pane.update_mounted_users
    end
  end

  def onMouseMove(_flags, x, y, view)
    @mouse_input.update_positions(view, x, y)
  end

  def onKeyDown(key, _repeat, _flags, _view)
    super
    if key == VK_RIGHT
      @hub.rotate_user(45.degrees)
    elsif key == VK_LEFT
      @hub.rotate_user(-45.degrees)
    end
  end

end
