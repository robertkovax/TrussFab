require 'src/tools/import_tool.rb'

class DynamicOctahedronTool < ImportTool
  def initialize(ui)
    super
    @path = Configuration::DYNAMIC_OCTAHEDRON_PATH
  end
end