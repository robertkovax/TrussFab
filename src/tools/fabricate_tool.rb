require 'src/tools/tool.rb'
require 'fileutils'

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
    # Copy script files into the folder
    # Mac stl script
    filename = ProjectHelper.library_directory + '/openscad/executeSCAD_Mac.sh'
    FileUtils.cp(filename, @path)
    # Windows stl script
    filename = ProjectHelper.library_directory + '/openscad/executeSCAD_Windows.cmd'
    FileUtils.cp(filename, @path)
    # Lassercutted welding jigs script
    # filename = ProjectHelper.library_directory + '/openscad/executeSCADForLaserCuttedJig.sh'
    # FileUtils.cp(filename, @path)
  end
end
