require 'src/tools/import_tool.rb'

# Asset tool that produces a tetra with an actuator
class DynamicTetrahedronTool < ImportTool
  def initialize(_ui)
    super
    @path = Configuration::DYNAMIC_TETRAHEDRON_PATH
  end
end
