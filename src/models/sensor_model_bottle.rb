class SensorModelBottle
  attr_reader :definition

  def initialize
    @definition = Sketchup.active_model.definitions.load(ProjectHelper.component_directory + '/sensor_bottle.skp')
    @definition.name = 'SensorBottle'
  end

  def valid?
    @definition.valid?
  end

end
