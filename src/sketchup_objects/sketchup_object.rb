require 'src/database/id_manager.rb'

# Wrapper for the representation of TrussFab objects in Sketchup (e.g. Hub,
# Link)
class SketchupObject
  attr_reader :id, :entity, :children, :position
  attr_accessor :parent

  def initialize(id = nil,
                 material:
                   Sketchup.active_model.materials['standard_material'],
                 highlight_material:
                   Sketchup.active_model.materials['highlight_material'])
    @id = id.nil? ? IdManager.instance.generate_next_id : id
    @children = []
    @entity = nil
    @parent = nil
    @material = material
    @highlight_material = highlight_material
    @deleted = false
  end

  def check_if_valid
    return false if @entity.nil? || (@entity && !@entity.valid?)
    @children.each do |child|
      return false unless child.check_if_valid
    end
    true
  end

  def all_entities
    entities = []
    entities.push(@entity) if @entity && @entity.valid?
    @children.each { |child| entities.concat(child.all_entities) }
    entities
  end

  def transform(transformation)
    @entity.move!(transformation) if @entity && @entity.valid?
    @children.each { |child| child.transform(transformation) }
  end

  def change_color(color)
    @entity.material = color if @entity && @entity.valid?
    @children.each { |child| child.change_color(color) }
  end

  def hide
    @entity.hidden = true if @entity && @entity.valid?
    @children.each(&:hide)
  end

  def show
    @entity.hidden = false if @entity && @entity.valid?
    @children.each(&:show)
  end

  def color
    @entity.material if @entity && @entity.valid?
  end

  def material=(material)
    @material = material
    @entity.material = material if @entity && @entity.valid?
    @children.each { |child| child.material = material }
  end

  def highlight(highlight_material = @highlight_material)
    change_color(highlight_material)
  end

  def un_highlight
    change_color(@material)
  end

  def delete_entity
    @entity.erase! if @entity && @entity.valid?
    @entity = nil
  end

  def delete
    delete_children
    delete_entity
    @parent.remove(self) unless @parent.nil?
    @deleted = true
  end

  def deleted?
    @deleted
  end

  def delete_child(id)
    @children.each do |child|
      next unless child.id == id
      child.delete
    end
  end

  def delete_children
    @children.clone.each(&:delete)
  end

  def remove(child)
    @children.delete(child)
  end

  def add(*children)
    children.each do |child|
      @children << child
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
