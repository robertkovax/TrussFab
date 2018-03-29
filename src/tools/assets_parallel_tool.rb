require 'src/tools/import_tool.rb'

class AssetsParallelTool < ImportTool
  def initialize(ui)
    super
    @path = Configuration::ASSETS_PARALLEL_PATH
  end
end
