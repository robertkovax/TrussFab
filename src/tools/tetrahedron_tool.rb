require 'src/tools/tool.rb'

class TetrahedronTool < JsonTool
  def initialize(ui)
    super
    @path = Configuration::TETRAHEDRON
  end
end
