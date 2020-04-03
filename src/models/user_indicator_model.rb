# User indicator model
class UserIndicatorModel
  attr_reader :definition

  def initialize(name: 'child')
    @definition = Sketchup.active_model.definitions
                          .load(ProjectHelper.component_directory +
                                  "/attachable_users/#{name}.skp")
  end

  def valid?
    @definition.valid?
  end
end
