class ForceArrowModel
  attr_reader :definition, :weight

  def initialize
    @definition = Sketchup.active_model.definitions.load(ProjectHelper.component_directory + '/force.skp')
    @definition.name = 'Force Arrow'
    @weight = 0
  end
end
