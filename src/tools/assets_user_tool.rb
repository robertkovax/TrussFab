require 'src/tools/import_tool.rb'

# places a TrussCube
class AssetsUserTool < ImportTool
  def initialize(_ui)
    super
    @path = Configuration::ASSETS_USER_PATH
  end
end
