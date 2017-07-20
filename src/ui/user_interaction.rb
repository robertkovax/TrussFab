ProjectHelper.require_multiple('src/tools/*.rb')

class UserInteraction
  def initialize
    @tools = {}
    @main_dialog = nil
    @timeline_dialog = nil
  end

  def deselect_tool
    @main_dialog.execute_script('deselect_all_tools()')
  end

  def open_main_dialog
    @main_dialog = UI::HtmlDialog.new(Configuration::MAIN_HTML_DIALOG)
    file = File.join(File.dirname(__FILE__), '/html/main_panel.html')
    @main_dialog.set_file(file)
    @main_dialog.show
    @main_dialog.add_action_callback('document_ready') { register_callbacks }
    @main_dialog.add_action_callback('open_timeline_panel') { open_timeline_dialog }
    @main_dialog.add_action_callback('button_clicked') do |_context, button_id|
      Sketchup.active_model.select_tool(@tools[button_id])
      @main_dialog.execute_script("select_tool('#{button_id}')")
    end
  end

  def close_main_dialog
    @main_dialog.close
    @main_dialog = nil
  end

  def open_timeline_dialog
    @timeline_dialog = UI::HtmlDialog.new(Configuration::TIMELINE_HTML_DIALOG)
    file = File.join(File.dirname(__FILE__), '/html/timeline_panel.html')
    @timeline_dialog.set_file(file)
    @timeline_dialog.show
  end

  def close_timeline_dialog
    @timeline_dialog.close
    @timeline_dialog = nil
  end

  private

  def register_callbacks
    return if @main_dialog.nil?
    build_tool(TetrahedronTool, 'tetrahedron_tool')
    build_tool(DynamicTetrahedronTool, 'dynamic_tetrahedron_tool')
    build_tool(OctahedronTool, 'octahedron_tool')
    build_tool(DynamicOctahedronTool, 'dynamic_octahedron_tool')
    build_tool(BottleLinkTool, 'bottle_link_tool')
    build_tool(DeleteTool, 'delete_tool')
    build_tool(GrowTool, 'grow_tool')
    build_tool(ShrinkTool, 'shrink_tool')
    build_tool(MoveTool, 'deform_tool')
    build_tool(ExportFileTool, 'export_file_tool')
    build_tool(ImportFileTool, 'import_file_tool')
    build_tool(PodTool, 'pod_tool')
    build_tool(SimulationTool, 'simulation_tool')
    build_tool(BallJointSimulationTool, 'ball_joint_simulation_tool')
    build_tool(ActuatorTool, 'actuator_tool')
  end

  def build_tool(tool_class, tool_id)
    @tools[tool_id] = tool_class.new(self)
  end
end
