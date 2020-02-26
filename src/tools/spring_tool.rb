require 'src/tools/link_tool.rb'

# creates a gas spring-type link
class SpringTool < ActuatorTool
  def initialize(ui)
    super(ui, 'spring')
  end

  def onLButtonDown(flags, x, y, view)
    super(flags, x, y, view)
    @ui.spring_pane.update_springs
  end
end
