require 'src/thingies/link_entities/link_entity.rb'

class Line < LinkEntity
  def initialize(first_position, second_position, id: nil)
    @first_position = first_position
    @second_position = second_position
    super(id)
  end

  def create_entity
    return @entity if @entity
    entity = Sketchup.active_model.entities.add_line(@first_position, @second_position)
    entity.smooth = true
    entity.layer = Configuration::LINE_VIEW
    entity
  end
end
