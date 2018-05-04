require 'src/tools/tool.rb'
require 'src/export/node_export_algorithm.rb'

# runs the hinge placement algorithm
class HingeAnalysisTool < Tool
  def activate
    hinge_algorithm = NodeExportAlgorithm.instance
    hinge_algorithm.run
  end
end
