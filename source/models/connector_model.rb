class ConnectorModel
  attr_reader :definition

  def initialize
    @definition = Sketchup.active_model.definitions.load ProjectHelper.component_directory + '/connector.skp'
    @definition.name = 'Connector'
  end
end
