require 'src/tools/pull_node_interaction_tool.rb'
require 'src/system_simulation/trace_visualization.rb'

# Applies a force in direction of the drawn vector to the pulled node in the modelica simulation.
class ApplyForceVectorTool < PullNodeInteractionTool
  AMPLIFICATION_FACTOR = 10

  def onLButtonUp(_flags, x, y, view)
    super
    return unless @moving
    return if @start_node.nil?

    vector = get_amplified_vector()
    force_vector = {node_id: @start_node.id, x: (vector.x).to_i, y: (vector.y).to_i,
                    z: (vector.z).to_i}

    puts "Applying (#{force_vector[:x]}N,#{force_vector[:y]}N,#{force_vector[:z]}N) to node ##{force_vector[:node_id]}"
    @ui.spring_pane.force_vectors = [force_vector]

    view.invalidate
    reset
  end

  # Update status text with currently applied force.
  def onMouseMove(_flags, x, y, view)
    super
    @mouse_input.update_positions(view, x, y, point_on_plane_from_camera_normal: @start_position || nil)
    return unless @moving
    @end_position = @mouse_input.position

    vector = get_amplified_vector()

    label_position = @end_position
    label_text = "#{(vector.length() * AMPLIFICATION_FACTOR).round}N"

    if !@label
      @label = Sketchup.active_model.entities.add_text(label_text, label_position)
    else
      @label.point = label_position
      @label.text = label_text
    end
  end

  def reset
    super
    Sketchup.active_model.entities.erase_entities @label
    @label = nil
  end

  def get_amplified_vector
    vector = @end_position - @start_position
    vector.length = vector.length * AMPLIFICATION_FACTOR if vector.length > 0
    vector
  end

end

