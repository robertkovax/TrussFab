require 'src/tools/link_tool.rb'
require 'src/export/node_export_visualization'

# creates a gas spring-type link
class SpringTool < ActuatorTool
  def initialize(ui)
    super(ui, 'spring')
  end

  def onLButtonDown(flags, x, y, view)
    super
    @ui.spring_pane.update_springs
    Sketchup.active_model.start_operation('Color static groups', true)
    static_groups = StaticGroupAnalysis.find_static_groups
    visualizer = NodeExportVisualization::Visualizer.new
    visualizer.color_static_groups static_groups
    Sketchup.active_model.commit_operation
  end
end
