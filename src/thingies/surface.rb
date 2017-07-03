require 'src/thingies/thingy.rb'
require 'src/thingies/surface_entities/cover.rb'

class Surface < Thingy
  def initialize(first_position, second_position, third_position,
                 id: nil, material: 'surface_material', highlight_color: Configuration::SURFACE_HIGHLIGHT_COLOR)
    super(id, material: material, highlight_color: highlight_color)
    @first_position = first_position
    @second_position = second_position
    @third_position = third_position
    @entity = create_entity
  end

  def color=(color)
    super(color)
    @entity.back_material.color = color
  end

  def highlight(highlight_color = @highlight_color)
    super(highlight_color)
    material.alpha = 1
  end

  def un_highlight
    super
    material.alpha = 0.03
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
    @first_position = first_position
    @second_position = second_position
    @third_position = third_position
    delete_entity
    @entity = create_entity
  end

  def add_cover(direction)
    pod_length = ModelStorage.instance.models['pod'].length
    offset_vector = direction.clone
    offset_vector.length = pod_length
    first_position = positions[0] + offset_vector
    second_position = positions[1] + offset_vector
    third_position = positions[2] + offset_vector
    add(Cover.new(first_position, second_position, third_position, direction))
  end

  def has_cover?
    not cover.nil?
  end

  def cover
    @sub_thingies.each do |thingy|
      return thingy if thingy.is_a?(Cover)
    end
    nil
  end

  private

  def create_entity
    entity = Sketchup.active_model.entities.add_face(@first_position, @second_position, @third_position)
    entity.layer = Configuration::TRIANGLE_SURFACES_VIEW
    entity.material = entity.back_material = @material
    entity.edges.each do |edge|
      # hide outline of surfaces, enable line link layer for lines instead of bottles
      edge.hidden = true
    end
    entity
  end
end
