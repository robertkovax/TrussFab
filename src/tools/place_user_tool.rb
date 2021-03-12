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
    return if obj.nil? || !obj.is_a?(Node)

    @hub = obj.hub
    possible_filenames = ModelStorage.instance.attachable_users.keys
    if @hub.is_user_attached
      current_name = @hub.user_indicator_filename
      current_index = possible_filenames.find_index current_name
      if current_index == possible_filenames.length - 1
        @hub.remove_user
      else
        attach_user(possible_filenames[current_index + 1])
      end
    else
      attach_user(possible_filenames[0])
    end
    closest_spring = @ui.spring_pane.spring_edges.min_by { |edge| edge.distance @hub.position}
    @ui.spring_pane.enable_preloading_for_spring(closest_spring.id) unless closest_spring.nil?
    # TODO: at some point springe pane should compile automatically when geometry changes
    # @ui.spring_pane.request_compilation
    @ui.spring_pane.update_mounted_users
  end

  def attach_user(file_name)
    if file_name.include?('sensor')
      @hub.attach_user(filename: file_name, excitement: 0)
    else
      @hub.attach_user(filename: file_name)
    end
  end

  def onMouseMove(_flags, x, y, view)
    @mouse_input.update_positions(view, x, y)
  end

  def onKeyDown(key, _repeat, flags, _view)
    super

    case key
    when VK_RIGHT
      @hub.rotate_user(ANGLE_ROTATION_STEP)
    when VK_LEFT
      @hub.rotate_user(-ANGLE_ROTATION_STEP)
    when VK_UP
      @hub.user_transformation *=
        Geom::Transformation.rotation(
          Geom::Point3d.new, Geom::Vector3d.new(1, 0, 0), ANGLE_ROTATION_STEP
        )
    when VK_DOWN
      @hub.user_transformation *=
        Geom::Transformation.rotation(
          Geom::Point3d.new, Geom::Vector3d.new(1, 0, 0), -ANGLE_ROTATION_STEP
        )
    else
      return
    end
  end
end
