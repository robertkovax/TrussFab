require 'test2.rb'
require 'src/tools/tool.rb'
require 'src/utility/mouse_input.rb'


class AnimationTool < Tool
  def initialize(ui)
    super
    @animation = Animation.instance
  end

  def activate
    @animation.setup
    Sketchup.active_model.active_view.animation = @animation
  end

  def deactivate(view)
    super
  end

  def onLButtonDown(_flags, x, y, view)
  end

  def onMouseMove(_flags, x, y, view)
  end

  def draw(view)
    @animation.draw_forces(view)
  end
  private

  def reset
  end
end
