require 'src/tools/import_tool.rb'

class DynamicTetrahedronTool < ImportTool
  def initialize(ui)
    super
    @path = Configuration::DYMAMIC_TETRAHEDRON_PATH
  end
end