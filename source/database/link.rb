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

  def delete
    @first_elongation.delete
    @first_elongation = nil
    @second_elongation.delete
    @second_elongatio = nil
    @first_connector.delete
    @first_connector = nil
    @second_connector.delete
    @second_connector = nil
    @line.delete
    @line = nil
    @model.delete
    @model = nil
    super
  end

  private
  def create_entity
    # this will group all entities into one
    # the context menu for elongations and connectors won't work, since the group will always be on the complete link
    # @entity = Sketchup.active_model.entities.add_group(entities)
  end

  def entities
    ents = Array.new
    ents << @first_elongation.entity
    ents << @first_connector.entity
    ents << @line.entity
    ents << @model.entity
    ents << @second_connector.entity
    ents << @second_elongation.entity
  end
end