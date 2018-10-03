require 'src/tools/tool.rb'

# exports hubs and hinges to scad file
class FabricateTool < Tool
  def activate
    if @path.nil?
      @path = UI.select_directory(title: 'Select scad export directory')
    else
      @path = UI.select_directory(title: 'Select scad export directory',
                                  directory: @path)
    end
    return if @path.nil?

    Graph.instance.export_to_scad(@path)
  end
end
