# User indicator model
class UserIndicatorModel
  attr_reader :definition

  def initialize
    @definition = Sketchup.active_model.definitions
                      .load(ProjectHelper.component_directory +
                                '/child.skp')
    @definition.name = 'User Indicator'
  end

  def valid?
    @definition.valid?
  end
end
