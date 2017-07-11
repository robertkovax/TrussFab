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

  def redraw
    delete_thingy
    @thingy = create_thingy(@id)
  end

  def highlight
    @thingy.highlight unless thingy.nil?
  end

  def un_highlight
    @thingy.un_highlight unless @thingy.nil?
  end

  private

  def create_thingy(_id)
    raise "GraphObject (#{self.class}):: create_thingy needs to be overwritten"
  end

  def unstore
    Graph.instance.delete_object(self)
  end

  def delete_thingy
    @thingy.delete if !@thingy.nil?
    @thingy = nil 
  end
end
