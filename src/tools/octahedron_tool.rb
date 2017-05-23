require 'src/tools/import_tool.rb'

class OctahedronTool < ImportTool
  def initialize(ui)
    super
    @path = Configuration::OCTAHEDRON_PATH
  end
end
