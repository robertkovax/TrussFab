require 'src/thingies/thingy.rb'

class Line < Thingy
  def initialize(first_position, second_position, id: nil)
    @first_position = first_position
    @second_position = second_position
    @entity = create_entity
    super(id)
  end

  def create_entity
    return @entity if @entity
    group = Sketchup.active_model.entities.add_group
    line = group.entities.add_line(@first_position, @second_position)
    line.smooth = true
    line.layer = Configuration::LINE_VIEW
    group
  end
end
