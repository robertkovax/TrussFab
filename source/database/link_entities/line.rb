require ProjectHelper.database_directory + '/link_entities/link_entity.rb'

class Line < LinkEntity
  def initialize first_position, second_position, id: nil
    super id
    @first_position = first_position
    @second_position = second_position
    @entity = Sketchup.active_model.entities.add_line first_position, second_position
    if @entity
      @entity.smooth = true
      @entity.layer = Configuration::LINE_VIEW
    end
  end
end