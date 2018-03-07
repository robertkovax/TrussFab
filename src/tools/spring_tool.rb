require 'src/tools/physics_link_tool.rb'

class SpringTool < PhysicsLinkTool
  def initialize(ui)
    super(ui, 'spring')
  end
end
