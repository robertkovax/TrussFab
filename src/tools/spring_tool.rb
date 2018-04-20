require 'src/tools/physics_link_tool.rb'

# creates a gas spring-type link
class SpringTool < PhysicsLinkTool
  def initialize(ui)
    super(ui, 'spring')
  end
end
