require 'src/thingies/thingy.rb'
require 'src/models/model_storage.rb'

class Hub < Thingy
  def initialize(position, id: nil, color: nil)
    super(id)
    @position = position
    @model = ModelStorage.instance.models['ball_hub']
    @color = color unless color.nil?
    @entity = create_entity
    @id_label = nil
    show_hub_id
  end

  def highlight(highlight_color = @highlight_color)
    change_color(highlight_color)
  end

  def un_highlight
    change_color(@color)
  end

  def update_position(position)
    @position = position
    @entity.move!(Geom::Transformation.new(position))
  end

  private

  def create_entity
    return @entity if @entity
    position = Geom::Transformation.translation(@position)
    transformation = position * @model.scaling
    entity = Sketchup.active_model.entities.add_instance(@model.definition,
                                                         transformation)
    entity.layer = Configuration::HUB_VIEW
    entity.material = @color
    entity
  end

  def show_hub_id
    label_position = Geom::Point3d.new(@position)
    if @id_label.nil?
      @id_label = Sketchup.active_model.entities.add_text("    #{id} ", label_position)
      @id_label.layer = Sketchup.active_model.layers[Configuration::HUB_ID_VIEW]
      puts @id_label.layer
    else
      @id_label.point = label_position
    end
  end
end
