require 'src/tools/import_tool.rb'

class ChairTool < ImportTool
  def initialize(ui)
    super
    @path = Configuration::CHAIR
  end
end
