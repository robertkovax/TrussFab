require ProjectHelper.database_directory + '/id_manager.rb'

class Thingy
  attr_reader :id

  def initialize id = nil
    @id = id.nil? ? IdManager.instance.generate_next_id : id
    @entity = nil
    create_entity
  end

  private
  def create_entity
    raise "Thingy (#{self.class}) :: create_entity needs to be overwritten"
  end
end