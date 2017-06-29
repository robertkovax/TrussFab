require 'src/thingies/thingy.rb'
require 'src/thingies/surface_entities/cover.rb'

class Surface < Thingy
  def initialize(first_position, second_position, third_position, id: nil, color: 'surface_color')
    super(id)
    @first_position = first_position
    @second_position = second_position
    @third_position = third_position
    @color = color
    @entity = create_entity
    @highlight_color = 'surface_highlighted_color'
  end

  def change_color(color)
    super(color)
    @entity.back_material = color
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

  def highlight(highlight_color = @highlight_color)
    change_color(highlight_color)
  end

  def un_highlight
    change_color(@color)
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

  private

  def create_entity
    entity = Sketchup.active_model.entities.add_face(@first_position, @second_position, @third_position)
    entity.layer = Configuration::TRIANGLE_SURFACES_VIEW
    entity.material = entity.back_material = @color
    entity.edges.each do |edge|
      # hide outline of surfaces, enable line link layer for lines instead of bottles
      edge.hidden = true
    end
    entity
  end
end
