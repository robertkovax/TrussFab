require 'src/tools/tool.rb'
require 'src/utility/mouse_input.rb'

class BottleLinkTool < Tool
  def initialize(ui)
    super
    @mouse_input = MouseInput.new(snap_to_nodes: true)
  end

  def activate
    reset
  end

  def deactivate(view)
    reset
    super
  end

  def onLButtonDown(_flags, x, y, view)
    # is it the first time the mouse goes down
    if @first_position.nil?
      Sketchup.active_model.start_operation('Create Bottle Link', true)
      @first_position = @mouse_input.update_positions(view, x, y)
      Sketchup.active_model.commit_operation
    else
      second_position = @mouse_input.update_positions(view, x, y, point_on_plane_from_camera_normal: @first_position)

      puts 'Create single bottle link'
      Sketchup.active_model.start_operation('Build Bottle Link', true, false, true)
      Graph.instance.create_edge_from_points(@first_position,
                                             second_position)
      Sketchup.active_model.commit_operation
      reset
    end
  end

  def onMouseMove(_flags, x, y, view)
    @mouse_input.update_positions(view, x, y)
  end

  private

  def reset
    @mouse_input.soft_reset
    @first_position = nil
  end
end
