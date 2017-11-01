require 'src/thingies/thingy.rb'

LINK_LINE = 0
HINGE_LINE = 1

class Line < Thingy
  def initialize(first_position, second_position, line_type, id: nil)
    super(id)
    @first_position = first_position
    @second_position = second_position
    @line_type = line_type
    @entity = create_entity
  end

  def create_entity
    return @entity if @entity
    group = Sketchup.active_model.entities.add_group
    line = group.entities.add_line(@first_position, @second_position)
    line.smooth = true
    if @line_type == LINK_LINE
      line.layer = Configuration::LINE_VIEW
    elsif @line_type == HINGE_LINE
      line.layer = Configuration::HINGE_VIEW
    end

    group
  end
end
