require 'src/tools/import_tool.rb'

# places a TrussCube
class TrussCubeTool < ImportTool
  def initialize(_ui)
    super
    @path = Configuration::TRUSS_CUBE_PATH
  end
end
