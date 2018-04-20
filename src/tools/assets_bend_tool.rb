require 'src/tools/import_tool.rb'

# Asset tool that produces two octas on top of each other with an actuator
# in the middle
class AssetsBendTool < ImportTool
  def initialize(_ui)
    super
    @path = Configuration::ASSETS_BEND_PATH
  end
end
