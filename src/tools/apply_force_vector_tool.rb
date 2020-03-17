require 'src/tools/pull_node_interaction_tool.rb'
require 'src/system_simulation/trace_visualization.rb'

# Applies a force in direction of the drawn vector to the pulled node in the modelica simulation.
class ApplyForceVectorTool < PullNodeInteractionTool

  def onLButtonUp(_flags, x, y, view)
    super
    return unless @moving
    return if @start_node.nil?

    amplification_factor = 10
    vector = @end_position - @start_position
    force_vector = {node_id: @start_node.id, x: (vector.x * amplification_factor).to_i, y: (vector.y * amplification_factor).to_i,
                    z: (vector.z * amplification_factor).to_i}
    puts "Applying (#{force_vector[:x]}N,#{force_vector[:y]}N,#{force_vector[:z]}N) to node ##{force_vector[:node_id]}"
    @ui.spring_pane.force_vectors = [force_vector]

    view.invalidate
    reset
  end

end

