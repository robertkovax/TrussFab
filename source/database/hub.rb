require ProjectHelper.database_directory + '/thingy.rb'
require ProjectHelper.model_directory + '/model_storage.rb'

class Hub < Thingy
  def initialize id, position
    @position = position
    @model = ModelStorage.instance.models['ball_hub']
    super id
  end

  private
  def create_entity
    unless @entity
      position = Geom::Transformation.translation @position
      transformation = position * @model.scaling
      @entity = Sketchup.active_model.entities.add_instance @model.definition, transformation
      @entity.layer = Configuration::HUB_VIEW
    end
    @entity
  end
end