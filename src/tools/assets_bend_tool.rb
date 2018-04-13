require 'src/tools/import_tool.rb'

class AssetsBendTool < ImportTool
  def initialize(ui)
    super
    @path = Configuration::ASSETS_BEND_PATH
  end
end
