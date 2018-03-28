require 'src/tools/import_tool.rb'

class AssetsHingeTool < ImportTool
  def initialize(ui)
    super
    @path = Configuration::ASSETS_HINGE_PATH
  end
end
