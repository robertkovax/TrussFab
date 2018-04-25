require 'src/tools/import_tool.rb'

# creates a tetra
class TetrahedronTool < ImportTool
  def initialize(ui)
    super
    @path = Configuration::TETRAHEDRON_PATH
  end
end
