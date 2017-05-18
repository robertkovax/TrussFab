require 'src/tools/import_tool.rb'

class OctahedronTool < ImportTool
  def initialize(ui)
    super
    @path = Configuration::OCTAHEDRON
  end
end
