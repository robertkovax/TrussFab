require 'src/tools/json_tool.rb'

class ChairTool < JsonTool
  def initialize(ui)
    super
    @path = Configuration::CHAIR
  end
end
