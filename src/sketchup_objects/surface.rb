require 'src/sketchup_objects/sketchup_object.rb'
require 'src/sketchup_objects/surface_entities/cover.rb'

# Surface
class Surface < SketchupObject
  def initialize(first_position, second_position, third_position,
                 id: nil, material: 'surface_material',
                 highlight_material: 'surface_highlight_material')
    super(id, material: material, highlight_material: highlight_material)
    @first_position = first_position
    @second_position = second_position
    @third_position = third_position
    @entity = create_entity
    @material = Sketchup.active_model.materials[material].freeze
    @highlight_material = Sketchup.active_model
                                  .materials[highlight_material].freeze
    persist_entity
  end

  def highlight(highlight_material = @highlight_material)
    super(highlight_material)
    @entity.back_material = highlight_material if @entity && @entity.valid?
  end

  def un_highlight
    @entity.back_material = @material if @entity && @entity.valid?
    super
  end

  def delete_edges(position)
    return if @entity.nil? || @entity.deleted?
    @entity.edges.each do |edge|
      if edge.line.include?(position) && !edge.nil? && !edge.deleted?
        edge.erase!
      end
    end
  end

  def positions
    [@first_position, @second_position, @third_position]
  end

  def update_positions(first_position, second_position, third_position)
    return if first_position == @first_position &&
      second_position == @second_position &&
      third_position == @third_position

    @first_position = first_position
    @second_position = second_position
    @third_position = third_position
    delete_entity
    @entity = create_entity
    @children.each do |child|
      child.update_positions(first_position,
                             second_position,
                             third_position)
    end
  end

  def add_cover(direction, pods)
    add(Cover.new(@first_position,
                  @second_position,
                  @third_position,
                  direction, pods))
  end

  def cover?
    @children.any? { |child| child.is_a?(Cover) }
  end

  def cover
    @children.detect { |child| child.is_a?(Cover) }
  end

  private

  def create_entity
    entity = Sketchup.active_model.entities.add_face(@first_position,
                                                     @second_position,
                                                     @third_position)
    entity.layer = Configuration::TRIANGLE_SURFACES_VIEW
    entity.material = entity.back_material = @material
    entity.edges.each do |edge|
      # hide outline of surfaces, enable line link layer for
      # lines instead of bottles
      edge.hidden = true
    end
    entity
  end
end
