# User indicator model
class UserIndicatorModel
  attr_reader :definition, :weight

  def initialize(name: 'child', weight: 100)
    @definition = Sketchup.active_model.definitions
                          .load(ProjectHelper.component_directory +
                                  "/attachable_users/#{name}-#{weight}.skp")
    @weight = weight
  end

  def valid?
    @definition.valid?
  end
end
