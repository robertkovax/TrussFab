require 'src/thingies/thingy.rb'
require 'src/thingies/surface_entities/cover.rb'

class Surface < Thingy
  def initialize(first_position, second_position, third_position,
                 id: nil, material: 'surface_material', highlight_material:'surface_highlight_material')
    super(id, material: material, highlight_material: highlight_material)
    @first_position = first_position
    @second_position = second_position
    @third_position = third_position
    @entity = create_entity
  end

  def highlight(highlight_material = @highlight_material)
    super(highlight_material)
    @entity.back_material = highlight_material
  end

  def un_highlight
    @entity.back_material = @material
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
    @first_position = first_position
    @second_position = second_position
    @third_position = third_position
    delete_entity
    @entity = create_entity
  end

  def add_cover(direction, pods)
    pod_length = ModelStorage.instance.models['pod'].length
    offset_vector = direction.clone
    offset_vector.length = pod_length
    first_position = positions[0] + offset_vector
    second_position = positions[1] + offset_vector
    third_position = positions[2] + offset_vector
    add(Cover.new(first_position, second_position, third_position, direction, pods))
  end

  def cover?
    !cover.nil?
  end

  def cover
    @sub_thingies.find { |thingy| thingy.is_a?(Cover) }
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
