require 'src/tools/import_tool.rb'

# Asset tool that produces the spider leg
class AssetsLegTool < ImportTool
  def initialize(_ui)
    super
    @path = Configuration::ASSETS_LEG_PATH
  end
end
