require ProjectHelper.database_directory + '/link_entities/connector.rb'
require ProjectHelper.database_directory + '/link_entities/elongation.rb'
require ProjectHelper.database_directory + '/link_entities/line.rb'
require ProjectHelper.database_directory + '/link_entities/bottle_link.rb'

class Link < Thingy
  def initialize first_position, second_position, definition, first_elongation_length, second_elongation_length,
                 id: nil
    @definition = definition
    @direction = first_position.vector_to second_position
    @first_position = first_position
    @first_elongation = Elongation.new first_position, @direction, first_elongation_length
    @first_connector = Connector.new first_position, @direction, first_elongation_length
    @line = Line.new first_position, second_position
    link_position = first_position.offset @first_elongation.direction
    @model = BottleLink.new link_position, @direction, definition
    @second_connector = Connector.new second_position, @direction.reverse, second_elongation_length
    @second_elongation = Elongation.new second_position, @direction.reverse, second_elongation_length
    @second_position = second_position
    super id
  end

  def length
    @first_position.distance @second_position
  end

  private
  def create_entity
    unless @entity
      @entity = nil
    end
    @entity
  end
end