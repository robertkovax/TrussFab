ProjectHelper.require_multiple('src/tools/*.rb')

class Sidebar
  attr_reader :width, :height

  attr_accessor :actuator_menu

  def initialize
    @tools = {}
    @HTML_FILE = '../html/sidebar.html'
  end

  def deselect_tool
    @dialog.execute_script('deselectAllTools()')
    Sketchup.active_model.select_tool(nil)
  end

  def open_dialog
    num_icons_in_row = 4
    icon_width = 54
    body_padding = 4
    magic_distance = 4 * 9


    @width = num_icons_in_row * icon_width + body_padding + magic_distance
    @height = 740

    props = {
      :resizable => false,
      :width => @width,
      :height => @height,
      :left => 0,
      :top => 100,
      :min_width => @width,
      :min_height => @height,
      :max_width => @width,
      :max_height => @height
    }

    @dialog = UI::HtmlDialog.new(props)
    file = File.join(File.dirname(__FILE__), @HTML_FILE)
    @dialog.set_file(file)
    # @dialog.set_siSkeze(Configuration::UI_WIDTH, Configuration::UI_HEIGHT)
    @dialog.set_position(0, 0)
    @dialog.show
    @dialog.add_action_callback('documentReady') { register_callbacks }
    @dialog.add_action_callback('buttonClicked') do |_, button_id|
      model = Sketchup.active_model
      # Deactivate Current tool
      model.select_tool nil
      # Ensure there is no missing definitions, layers, and materials
      model.start_operation('TrussFab Setup', true)
      ProjectHelper.setup_layers
      ProjectHelper.setup_surface_materials
      ModelStorage.instance.setup_models
      model.commit_operation
      # This removes all deleted nodes and edges from storage
      Graph.instance.cleanup
      # Now, select the new tool
      model.select_tool(@tools[button_id])
      @dialog.execute_script("selectTool('#{button_id}')")
    end
    @dialog
  end

  def close_dialog
    @dialog.close
  end

  def refresh
    file = File.join(File.dirname(__FILE__), @HTML_FILE)
    @dialog.set_file(file)
  end

  private

  def register_callbacks
    return if @dialog.nil?
    build_tool(TetrahedronTool, 'tetrahedron_tool')
    build_tool(AssetsLegTool, 'assets_leg_tool')
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
    build_tool(SensorTool, 'sensor_tool')
    build_tool(SimulationTool, 'simulation_tool')
    build_tool(AddForceTool, 'add_force_tool')
    build_tool(AddWeightTool, 'add_weight_tool')
    build_tool(AddWeightTool, 'add_force_tool') # TODO
    build_tool(ActuatorTool, 'actuator_tool')
    build_tool(SpringTool, 'spring_tool')
    build_tool(GenericPhysicsLinkTool, 'generic_physics_link_tool')
    build_tool(CoverTool, 'cover_tool')
    build_tool(FabricateTool, 'fabricate_tool')
    build_tool(BottleCountTool, 'bottle_count_tool')
    build_tool(RigidityTestTool, 'rigidity_test_tool')
    build_tool(HingeAnalysisTool, 'hinge_analysis_tool')
    build_tool(AutomaticActuatorsTool, 'automatic_actuators_tool')
    build_tool(GeneticActuatorPlacementTool, 'genetic_actuator_placement_tool')
  end

  def build_tool(tool_class, tool_id)
    @tools[tool_id] = tool_class.new(self)
  end
end
