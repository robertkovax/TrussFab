require 'src/tools/import_tool.rb'

# Asset tool that produces a 2DOF octa
class AssetsParallelTool < ImportTool
  def initialize(_ui)
    super
    @path = Configuration::ASSETS_PARALLEL_PATH
  end
end
