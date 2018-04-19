require 'src/tools/tool.rb'

class FabricateTool < Tool
  def activate
    path = UI.select_directory(title: 'Select scad export directory')
    Graph.instance.export_to_scad(path)
  end
end
