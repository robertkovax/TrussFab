require 'src/models/physics_link_model.rb'

# Spring model (green)
class SpringModel
  attr_reader :definition, :material

  def initialize
    # super
    @definition = Sketchup.active_model.definitions
                    .load(ProjectHelper.component_directory +
                            '/spring_model_sketchup_store.skp')
    @definition.name = 'Spring'

    @material = Sketchup.active_model.materials['spring_material']
  end

  def valid?
    @definition.valid?
  end
end
