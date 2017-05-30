require 'src/tools/import_tool.rb'

class TetrahedronTool < ImportTool
  def initialize(ui)
    super
    @path = Configuration::TETRAHEDRON_PATH
  end
end
