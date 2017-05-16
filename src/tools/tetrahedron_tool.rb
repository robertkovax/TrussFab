require 'src/tools/tool.rb'
require 'src/utility/mouse_input.rb'
require 'src/utility/json_import.rb'
require 'src/utility/tetrahedron.rb'

class TetrahedronTool < Tool
  def initialize(ui = nil)
    super
    @path = Configuration::TETRAHEDRON
  end
end
