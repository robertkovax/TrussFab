require 'src/tools/link_tool.rb'

# creates a gas spring-type link
class SpringTool < ActuatorTool
  def initialize(ui)
    super(ui, 'spring')
  end
end
