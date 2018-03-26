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
    persist_entity
  end

  def create_entity
    Sketchup.active_model.start_operation('Line: Create', true, false, true)
    return @entity if @entity
    group = Sketchup.active_model.entities.add_group
    line = group.entities.add_line(@first_position, @second_position)
    line.smooth = true
    if @line_type == LINK_LINE
      line.layer = Configuration::LINE_VIEW
    elsif @line_type == HINGE_LINE
      line.layer = Configuration::HINGE_VIEW
    end
    Sketchup.active_model.commit_operation

    group
  end
end
