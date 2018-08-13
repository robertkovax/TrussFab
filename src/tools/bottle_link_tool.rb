require 'src/tools/tool.rb'
require 'src/utility/mouse_input.rb'

# Creates a bottle link between two nodes
class BottleLinkTool < LinkTool
  def initialize(ui)
    super(ui, 'bottle_link')
  end

  def activate
    Sketchup.active_model.selection.each do |element|
      next unless element.kind_of? Sketchup::Edge
      create_link element.start.position, element.end.position
    end
  end
end
