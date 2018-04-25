require 'src/tools/import_tool.rb'

# Asset tool that produces an octa with an actuator
class DynamicOctahedronTool < ImportTool
  def initialize(_ui)
    super
    @path = Configuration::DYNAMIC_OCTAHEDRON_PATH
  end
end
