require 'src/tools/link_tool.rb'

# creates a metal spring-type link
class MetalSpringTool < LinkTool
  def initialize(ui)
    super(ui, 'metal_spring')
	#puts "MetalSpringTool initialized"
  end
end
