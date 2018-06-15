require 'src/tools/link_tool.rb'

# Tool that places a generic link (i.e. a link that can be used with a custom
# force function) between two hubs or turns an existing edge into a generic link
class GenericPhysicsLinkTool < LinkTool
  def initialize(ui, link_type: 'generic')
    super(ui, link_type)
  end
end
