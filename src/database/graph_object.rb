require 'src/database/id_manager.rb'

class GraphObject
  attr_reader :id, :thingy

  def initialize(id = nil)
    @id = id.nil? ? IdManager.instance.generate_next_id : id
    @thingy = create_thingy(@id)
    @deleted = false
  end

  def check_if_valid
    (@thingy && @thingy.check_if_valid) ? true : false
  end

  def delete
    delete_thingy
    Graph.instance.delete_object(self)
    @deleted = true
  end

  def deleted?
    @deleted
  end

  def redraw
    delete_thingy
    @thingy = create_thingy(@id)
  end

  def highlight
    @thingy.highlight unless @thingy.nil?
  end

  def un_highlight
    @thingy.un_highlight unless @thingy.nil?
  end

  private

  def create_thingy(_id)
    raise "GraphObject (#{self.class}):: create_thingy needs to be overwritten"
  end

  def recreate_thingy
    @thingy.delete
    @thingy = create_thingy(@id)
  end

  def delete_thingy
    @thingy.delete unless @thingy.nil?
    @thingy = nil
  end
end
