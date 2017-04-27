require 'src/database/thingy.rb'
require 'src/models/model_storage.rb'

class Hub < Thingy
  def initialize(position, id: nil)
    @position = position
    @model = ModelStorage.instance.models['ball_hub']
    super(id)
  end

  private

  def create_entity
    return @entity if @entity
    position = Geom::Transformation.translation @position
    transformation = position * @model.scaling
    @entity = Sketchup.active_model.entities.add_instance(@model.definition, transformation)
    @entity.layer = Configuration::HUB_VIEW
    @entity
  end
end
