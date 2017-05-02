require 'src/database/id_manager.rb'

class Thingy
  attr_reader :id

  def initialize(id = nil, color = 'standard_color')
    @id = id.nil? ? IdManager.instance.generate_next_id : id
    @entity = nil
    @color = color
    create_entity
  end

  def highlight(color = 'highlight_color')
    @entity.material = @entity.back_material = color
  end

  def un_highlight
    @entity.material = @entity.back_material = @color
  end

  def delete
    delete_entity
  end

  private

  def create_entity
    raise "Thingy (#{self.class}) :: create_entity needs to be overwritten"
  end

  def delete_entity
    @entity.erase! unless @entity.nil? || @entity.deleted?
    @entity = nil
  end
end
