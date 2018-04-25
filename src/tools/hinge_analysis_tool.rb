require 'src/tools/tool.rb'
require 'src/export/hinge_placement_algorithm.rb'

# runs the hinge placement algorithm
class HingeAnalysisTool < Tool
  def activate
    hinge_algorithm = HingePlacementAlgorithm.instance
    hinge_algorithm.run
  end
end
