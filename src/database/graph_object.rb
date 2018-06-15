require 'src/database/id_manager.rb'

# Object like Edge, Node, Surface
class GraphObject
  attr_reader :id

  def initialize(id = nil)
    @id = id.nil? ? IdManager.instance.generate_next_id : id
    @sketchup_object = create_sketchup_object(@id)
    @deleted = false
  end

  def check_if_valid
    @sketchup_object && @sketchup_object.check_if_valid
  end

  def delete
    delete_sketchup_object
    Graph.instance.delete_object(self)
    @deleted = true
  end

  def deleted?
    @deleted
  end

  def redraw
    delete_sketchup_object
    @sketchup_object = create_sketchup_object(@id)
  end

  def highlight
    @sketchup_object.highlight unless @sketchup_object.nil?
  end

  def un_highlight
    @sketchup_object.un_highlight unless @sketchup_object.nil?
  end

  private

  def create_sketchup_object(_id)
    raise "GraphObject (#{self.class})::create_sketchup_object needs to be overwritten"
  end

  def recreate_sketchup_object
    @sketchup_object.delete
    @sketchup_object = create_sketchup_object(@id)
  end

  def delete_sketchup_object
    @sketchup_object.delete unless @sketchup_object.nil?
    @sketchup_object = nil
  end
end
