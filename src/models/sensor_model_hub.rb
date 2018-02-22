class SensorModelHub
  attr_reader :definition

  def initialize
    @definition = Sketchup.active_model.definitions.load(ProjectHelper.component_directory + '/sensor_hub.skp')
    @definition.name = 'SensorHub'
  end

  def valid?
    @definition.valid?
  end

end
