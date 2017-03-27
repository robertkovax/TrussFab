class LinkEntity
  attr_reader :id, :entity

  def initialize id = nil
    @id = id.nil? ? IdManager.instance.generate_next_id : id
  end
end