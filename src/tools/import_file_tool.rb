require 'src/tools/import_tool.rb'
require 'src/configuration/configuration.rb'

# Opens the file select window for the import tool
class ImportFileTool < ImportTool
  def initialize(_ui)
    super
  end

  def activate
    @path = Configuration::JSON_PATH if @path.nil?
    @path = UI.openpanel('Open JSON',
                         @path,
                         'JSON File|*.json;||')
  end

  def onLButtonUp(_flags, _x, _y, _view); end
end
