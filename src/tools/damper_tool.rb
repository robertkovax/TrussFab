require 'src/tools/link_tool.rb'

class DamperTool < LinkTool
  def initialize(ui)
    super(ui, 'damper')
	#puts "MetalSpringTool initialized"
  end
end
