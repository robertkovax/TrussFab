require 'src/tools/link_tool.rb'

# creates a gas spring-type link
class SpringTool < LinkTool
  def initialize(ui)
    super(ui, 'actuator')
  end
end
