require 'src/tools/import_tool.rb'

class AssetsLegTool < ImportTool
  def initialize(ui)
    super
    @path = Configuration::ASSETS_LEG_PATH
  end
end