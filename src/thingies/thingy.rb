require 'src/database/id_manager.rb'

# Thingy (e.g. Hub, Link)
class Thingy
  attr_reader :id, :entity, :sub_thingies, :position
  attr_accessor :parent

  def initialize(id = nil,
                 material: 'standard_material',
                 highlight_material: 'highlight_material')
    @id = id.nil? ? IdManager.instance.generate_next_id : id
    @sub_thingies = []
    @entity = nil
    @parent = nil
    @material = Sketchup.active_model.materials[material]
    @highlight_material = Sketchup.active_model.materials[highlight_material]
    @deleted = false
  end

  def check_if_valid
    return false if @entity && !@entity.valid?
    @sub_thingies.each do |sub_thingy|
      return false unless sub_thingy.check_if_valid
    end
    true
  end

  def all_entities
    entities = []
    entities.push(@entity) if @entity && @entity.valid?
    @sub_thingies.each { |thingy| entities.concat(thingy.all_entities) }
    entities
  end

  def transform(transformation)
    Sketchup.active_model.start_operation('Transform', true)
    @entity.move!(transformation) if @entity && @entity.valid?
    @sub_thingies.each { |thingy| thingy.transform(transformation) }
    Sketchup.active_model.commit_operation
  end

  def change_color(color)
    Sketchup.active_model.start_operation('Change Color', true)
    @entity.material = color if @entity && @entity.valid?
    @sub_thingies.each { |thingy| thingy.change_color(color) }
    Sketchup.active_model.commit_operation
  end

  def hide
    Sketchup.active_model.start_operation('Hide', true)
    @entity.hidden = true if @entity && @entity.valid?
    @sub_thingies.each(&:hide)
    Sketchup.active_model.commit_operation
  end

  def show
    Sketchup.active_model.start_operation('Unhide', true)
    @entity.hidden = false if @entity && @entity.valid?
    @sub_thingies.each(&:show)
    Sketchup.active_model.commit_operation
  end

  def color
    @entity.material if @entity && @entity.valid?
  end

  def material=(material)
    Sketchup.active_model.start_operation('Thingy: Change Material', true)
    @entity.material = material if @entity && @entity.valid?
    @sub_thingies.each { |thingy| thingy.material = material }
    Sketchup.active_model.commit_operation
  end

  def highlight(highlight_material = @highlight_material)
    @entity.material = highlight_material if @entity && @entity.valid?
    @sub_thingies.each { |thingy| thingy.highlight(highlight_material) }
  end

  def un_highlight
    @entity.material = @material if @entity && @entity.valid?
    @sub_thingies.each(&:un_highlight)
  end

  def delete_entity
    @entity.erase! if @entity && @entity.valid?
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

  def persist_entity(type: self.class.to_s, id: self.id)
    return if @entity.nil?
    @entity.set_attribute('attributes', :type, type)
    @entity.set_attribute('attributes', :id, id)
  end
end
