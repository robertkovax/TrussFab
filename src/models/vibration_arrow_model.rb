# VibrationArrowModel
class VibrationArrowModel
  attr_reader :definition, :weight

  def initialize
    @definition = Sketchup.active_model.definitions
                    .load(ProjectHelper.component_directory +
                              '/vibration_arrow.skp')
    @definition.name = 'Vibration Arrow'
    @weight = 0
  end

  def valid?
    @definition.valid?
  end
end
