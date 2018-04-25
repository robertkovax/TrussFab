# ForceArrowModel
class ForceArrowModel
  attr_reader :definition, :weight

  def initialize
    @definition = Sketchup.active_model.definitions
                          .load(ProjectHelper.component_directory +
                                '/force_arrow.skp')
    @definition.name = 'Force Arrow'
    @weight = 0
  end

  def valid?
    @definition.valid?
  end
end
