class WeightIndicatorModel
  attr_reader :definition

  def initialize
    @definition = Sketchup.active_model.definitions.load(ProjectHelper.component_directory + '/pod.skp')
    @definition.name = 'Weight Indicator'
  end

  def valid?
    @definition.valid?
  end

end
