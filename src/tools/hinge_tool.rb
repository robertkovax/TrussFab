require 'src/tools/tool.rb'
require 'src/export/export_algorithm.rb'

class HingeTool < Tool
  def activate
    export_algorithm = ExportAlgorithm.instance
    export_algorithm.run
  end
end
