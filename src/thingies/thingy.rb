require 'src/database/id_manager.rb'

class Thingy
  attr_reader :id, :entity, :sub_thingies, :position
  attr_accessor :parent

  def initialize(id = nil)
    @id = id.nil? ? IdManager.instance.generate_next_id : id
    @sub_thingies = []
    @entity = nil
    @parent = nil
    @highlight_color = 'highlight_color'
  end

  def all_entities
    entities = []
    entities.push(@entity) unless @entity.nil?
    @sub_thingies.each do |thingy|
      entities.concat(thingy.all_entities)
    end
    entities
  end

  def transform(transformation)
    @entity.transform!(transformation) unless @entity.nil?
    @sub_thingies.each { |thingy| thingy.transform(transformation) }
  end

  def change_color(color)
    @entity.material = color unless @entity.nil?
    @sub_thingies.each { |thingy| thingy.change_color(color) }
  end

  def hide
    @entity.hidden = true unless @entity.nil?
    @sub_thingies.each(&:hide)
  end

  def show
    @entity.hidden = false unless @entity.nil?
    @sub_thingies.each(&:hide)
  end

  def color
    @entity.material unless @entity.nil?
  end

  def highlight(highlight_color = @highlight_color)
    @sub_thingies.each { |thingy| thingy.highlight(highlight_color) }
  end

  def un_highlight
    @sub_thingies.each(&:un_highlight)
  end

  def delete_entity
    @entity.erase! unless @entity.nil? || @entity.deleted?
    @entity = nil
  end

  def delete
    delete_sub_thingies
    delete_entity
    @parent.remove(self) unless @parent.nil?
  end

  def delete_sub_thingies
    @sub_thingies.clone.each(&:delete)
  end

  def remove(child)
    @sub_thingies.delete(child)
  end

  def add(*children)
    children.each do |child|
      @sub_thingies << child
      child.parent = self
    end
  end
end
