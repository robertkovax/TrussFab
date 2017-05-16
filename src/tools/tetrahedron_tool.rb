require 'src/tools/tool.rb'

class TetrahedronTool < JsonTool
  def initialize()
    super
    @path = Configuration::TETRAHEDRON
  end
end
