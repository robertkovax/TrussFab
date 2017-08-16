require 'src/database/id_manager.rb'

class Thingy
  attr_reader :id, :entity, :sub_thingies, :position
  attr_accessor :parent

  def initialize(id = nil, material: 'standard_material', highlight_material: 'highlight_material')
    @id = id.nil? ? IdManager.instance.generate_next_id : id
    @sub_thingies = []
    @entity = nil
    @parent = nil
    @material = Sketchup.active_model.materials[material]
    @highlight_material = Sketchup.active_model.materials[highlight_material]
    @deleted = false
  end

  def material=(material)
    @material = material
    @entity.material = material
    @sub_thingies.each { |thingy| thingy.material = material }
  end

  def highlight(highlight_material = @highlight_material)
    @entity.material = highlight_material unless @entity.nil?
    @sub_thingies.each { |thingy| thingy.highlight(highlight_material) }
  end

  def un_highlight
    @entity.material = @material unless @entity.nil?
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
    @deleted = true
  end

  def deleted?
    @deleted
  end

  def delete_sub_thingy(id)
    @sub_thingies.each do |sub_thingy|
      next unless sub_thingy.id == id
      sub_thingy.delete
      remove(sub_thingy)
    end
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
