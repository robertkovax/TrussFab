require 'src/database/id_manager.rb'

class Thingy
  attr_reader :id, :entity, :sub_thingies, :position
  attr_accessor :parent

  def initialize(id = nil, material: 'standard_material', highlight_color: Configuration::HIGHLIGHT_COLOR)
    @id = id.nil? ? IdManager.instance.generate_next_id : id
    @sub_thingies = []
    @entity = nil
    @parent = nil
    @material = Sketchup.active_model.materials[material]
    @highlight_color = highlight_color
  end

  def color=(color)
    @material.color = color unless material.nil?
    @entity.material = @material unless @enitty.nil?
    @sub_thingies.each { |thingy| thingy.color = color }
  end

  def material=(material)
    @material = material
    @entity.material = @material
    @sub_thingies.each { |thingy| thingy.material = material }
  end

  def color
    @material.color unless @material.nil?
  end

  def material
    @material unless @material.nil?
  end

  def highlight(highlight_color = @highlight_color)
    @last_color = color
    self.color = highlight_color
    @sub_thingies.each { |thingy| thingy.highlight(highlight_color) }
  end

  def un_highlight
    self.color = @last_color unless @last_color.nil?
    @last_color = nil
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

  def create_entity
    raise NotImplementedError
  end
end
