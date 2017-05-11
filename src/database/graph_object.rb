require 'src/database/id_manager.rb'

class GraphObject
  attr_reader :id, :thingy

  def initialize(id = nil)
    @id = id.nil? ? IdManager.instance.generate_next_id : id
    @thingy = create_thingy(@id)
  end

  def delete
    delete_thingy
    unstore
  end

  private

  def create_thingy(_id)
    raise "GraphObject (#{self.class}):: create_thingy needs to be overwritten"
  end

  def unstore
    Graph.instance.delete_object(self)
  end

  def delete_thingy
    @thingy.delete
  end
end
