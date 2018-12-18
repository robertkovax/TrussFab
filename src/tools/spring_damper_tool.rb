require 'src/tools/link_tool.rb'

class SpringDamperTool < LinkTool
  def initialize(ui)
    super(ui, 'spring_damper')
  end
end
