require 'src/database/thingy.rb'
require 'src/models/model_storage.rb'

class Hub < Thingy
  def initialize(position, id: nil, color: 'standard_color')
    super(id)
    @position = position
    @model = ModelStorage.instance.models['ball_hub']
    @color = color
    @entity = create_entity
  end

  def highlight(highlight_color = @highlight_color)
    change_color(highlight_color)
  end

  def un_highlight
    change_color(@color)
  end

  private

  def create_entity
    return @entity if @entity
    position = Geom::Transformation.translation(@position)
    transformation = position * @model.scaling
    entity = Sketchup.active_model.entities.add_instance(@model.definition, transformation)
    entity.layer = Configuration::HUB_VIEW
    entity.material = @color
    entity
  end
end
