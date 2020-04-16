# Places a user into the geometry i.e. someone who is injecting force into the system. This tool simulates the system
# and opens a panel that shows information and the possibility to change parameters of the springs.
class PlaceUserTool < Tool

  ANGLE_ROTATION_STEP = 5.degrees

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
      possible_names = ModelStorage.instance.attachable_users.keys
      if @hub.is_user_attached
        current_name = @hub.user_indicator_name
        current_index = possible_names.find_index current_name
        if current_index == possible_names.length - 1
          @hub.remove_user
        else
          @hub.attach_user(name: possible_names[current_index + 1])
        end
      else
        @hub.attach_user(name: possible_names[0])
      end
      # TODO: at some point springe pane should compile automatically when geometry changes
      @ui.spring_pane.compile
      @ui.spring_pane.update_mounted_users
    end
  end

  def onMouseMove(_flags, x, y, view)
    @mouse_input.update_positions(view, x, y)
  end

  def onKeyDown(key, _repeat, flags, _view)
    super

    if key == VK_RIGHT
      @hub.rotate_user(ANGLE_ROTATION_STEP)
    elsif key == VK_LEFT
      @hub.rotate_user(-ANGLE_ROTATION_STEP)
    elsif key == VK_UP
      @hub.user_transformation *=
        Geom::Transformation.rotation(
          Geom::Point3d.new, Geom::Vector3d.new(1, 0, 0), ANGLE_ROTATION_STEP
        )
    elsif key == VK_DOWN
      @hub.user_transformation *=
        Geom::Transformation.rotation(
          Geom::Point3d.new, Geom::Vector3d.new(1, 0, 0), -ANGLE_ROTATION_STEP
        )
    end
  end

end
