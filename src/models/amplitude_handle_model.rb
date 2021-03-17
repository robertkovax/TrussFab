# Weight indicator model
class AmplitudeHandleModel
  attr_reader :definition

  def initialize
    @definition = Sketchup.active_model.definitions
                          .load(ProjectHelper.component_directory +
                                '/handle_model.skp')
    @definition.name = 'Amplitude Handle'
  end

  def valid?
    @definition.valid?
  end
end
