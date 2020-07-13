require 'src/system_simulation/trace_visualization.rb'

class InspectTool < Tool

  def onMouseMove(_flags, x, y, view)
    input_point = Sketchup::InputPoint.new
    input_point.pick(view, x, y, Sketchup::InputPoint.new)
    position = input_point.position
    data_sample_visualization = @ui.spring_pane.trace_visualization.closest_visualization(position)

    @last_highlighted_visualization.un_highlight if @last_highlighted_visualization &&
        @last_highlighted_visualization != data_sample_visualization &&
        @ui.spring_pane.trace_visualization.visualization_valid?(@last_highlighted_visualization)
    data_sample_visualization.highlight
    @last_highlighted_visualization = data_sample_visualization
  end

end
