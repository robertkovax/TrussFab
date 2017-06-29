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
    @mouse_input.update_positions(view, x, y)
    if @first_touch
      @first_position = @mouse_input.position
      @first_touch = false
    else
      second_position = @mouse_input.position
      puts 'Create single bottle link'
      Sketchup.active_model.start_operation('Create bottle link', true)
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
    @first_touch = true
  end
end
