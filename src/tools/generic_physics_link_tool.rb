require 'src/tools/physics_link_tool.rb'

class GenericPhysicsLinkTool < PhysicsLinkTool
  def initialize(ui)
    super(ui, 'generic')
  end
end
