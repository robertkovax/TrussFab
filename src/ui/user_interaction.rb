ProjectHelper.require_multiple('src/tools/*.rb')

class UserInteraction
  def initialize
    @tools = {}
  end

  def deselect_tool
    @dialog.execute_script('deselect_all_tools()')
  end

  def open_dialog
    @dialog = UI::HtmlDialog.new(Configuration::HTML_DIALOG)
    file = File.join(File.dirname(__FILE__), '/html/user_interaction.html')
    @dialog.set_file(file)
    @dialog.show
    @dialog.add_action_callback('document_ready') { register_callbacks }
    @dialog.add_action_callback('button_clicked') do |_context, button_id|
      Sketchup.active_model.select_tool(@tools[button_id])
      @dialog.execute_script("select_tool('#{button_id}')")
    end
  end

  def close_dialog
    @dialog.close
  end

  private

  def register_callbacks
    return if @dialog.nil?
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
    build_tool(AddWeightTool, 'add_weight_tool')
    build_tool(BallJointSimulationTool, 'ball_joint_simulation_tool')
    build_tool(ActuatorTool, 'actuator_tool')
    build_tool(CoverTool, 'cover_tool')
    build_tool(FabricateTool, 'fabricate_tool')
    build_tool(BottleCountTool, 'bottle_count_tool')
    build_tool(RigidityTestTool, 'rigidity_test_tool')
    build_tool(HingeTool, 'hinge_tool')
    build_tool(AutomaticActuatorsTool, 'automatic_actuators_tool')
  end

  def build_tool(tool_class, tool_id)
    @tools[tool_id] = tool_class.new(self)
  end
end
