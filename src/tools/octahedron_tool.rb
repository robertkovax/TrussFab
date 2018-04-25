require 'src/tools/import_tool.rb'

# places an octa
class OctahedronTool < ImportTool
  def initialize(_ui)
    super
    @path = Configuration::OCTAHEDRON_PATH
  end
end
