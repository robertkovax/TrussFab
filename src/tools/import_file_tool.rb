require 'src/tools/import_tool.rb'
require 'src/configuration/configuration.rb'

class ImportFileTool < ImportTool
  def initialize(ui)
    super
  end

  def activate
    @path = UI.openpanel('Open JSON',
                         Configuration::JSON_PATH,
                         'JSON File|*.json;||')
  end

  def onLButtonUp(_flags, _x, _y, _view)
  end
end
