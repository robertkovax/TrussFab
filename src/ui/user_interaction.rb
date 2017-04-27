ProjectHelper.require_multiple('src/tools/*.rb')
puts 'UserInteraction'

class UserInteraction
  def initialize
    @tools = {}
    open_dialog
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

  private

  def register_callbacks
    return if @dialog.nil?
    build_tool(TetrahedronTool, 'tetrahedron_tool')
    build_tool(OctahedronTool, 'octahedron_tool')
    build_tool(BottleLinkTool, 'bottle_link_tool')
    build_tool(DeleteTool, 'delete_tool')
  end

  def build_tool(tool_class, tool_id)
    @tools[tool_id] = tool_class.new(self)
  end
end
