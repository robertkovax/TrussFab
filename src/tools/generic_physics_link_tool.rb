require 'src/tools/physics_link_tool.rb'

# Tool that places a generic link (i.e. a link that can be used with a custom
# force function) between two hubs or turns an existing edge into a generic link
class GenericPhysicsLinkTool < PhysicsLinkTool
  def initialize(ui)
    super(ui, 'generic')
  end
end
