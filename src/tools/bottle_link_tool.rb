require 'src/tools/tool.rb'
require 'src/utility/mouse_input.rb'

# Creates a bottle link between two nodes
class BottleLinkTool < LinkTool
  def initialize(ui)
    super(ui, 'bottle_link')
  end
end
