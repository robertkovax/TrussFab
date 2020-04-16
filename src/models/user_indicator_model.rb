# User indicator model
class UserIndicatorModel
  attr_reader :definition, :filename, :default_weight, :name

  def initialize(filename: 'boy-100.skp')
    @definition = Sketchup.active_model.definitions
                          .load(ProjectHelper.component_directory +
                                  "/attachable_users/#{filename}")
    @filename = filename
    basename = File.basename(filename, '.skp')
    name, default_weight = basename.split('-')
    @name = name
    @default_weight = default_weight.to_i
  end

  def valid?
    @definition.valid?
  end
end
