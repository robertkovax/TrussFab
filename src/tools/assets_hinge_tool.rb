require 'src/tools/import_tool.rb'

# Asset tool that produces two hinging tetras
class AssetsHingeTool < ImportTool
  def initialize(_ui)
    super
    @path = Configuration::ASSETS_HINGE_PATH
  end
end
