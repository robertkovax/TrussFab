require 'src/database/link_entities/connector.rb'
require 'src/database/link_entities/elongation.rb'
require 'src/database/link_entities/line.rb'
require 'src/database/link_entities/bottle_link.rb'

class Link < Thingy
  def initialize(first_position, second_position, definition, first_elongation_length, second_elongation_length,
                 id: nil)
    super(id)
    direction = first_position.vector_to(second_position)

    @first_position = first_position
    @second_position = second_position
    first_elongation = Elongation.new(first_position, direction, first_elongation_length)
    link_position = first_position.offset(first_elongation.direction)

    children = [
      Connector.new(first_position, direction, first_elongation_length),
      first_elongation,
      BottleLink.new(link_position, direction, definition),
      Elongation.new(second_position, direction.reverse, second_elongation_length),
      Connector.new(second_position, direction.reverse, second_elongation_length)
    ]

    children.each { |child| add(child) }
  end

  def length
    @first_position.distance(@second_position)
  end
end
