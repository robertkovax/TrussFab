require 'src/tools/import_tool.rb'
require 'src/configuration/configuration.rb'

# Opens the file select window for the import tool
class ImportFileTool < ImportTool
  def initialize(_ui)
    super
  end

  def activate
    super
    @import_path = if @import_path.nil?
      Configuration::JSON_PATH
    else
      File.dirname(@import_path)
                   end
    @import_path = UI.openpanel('Open JSON',
                                @import_path,
                                'JSON File|*.json;||')
    @path = @import_path
  end

  def onLButtonUp(_flags, _x, _y, _view); end
end
