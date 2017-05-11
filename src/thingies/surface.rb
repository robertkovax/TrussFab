require 'src/thingies/thingy.rb'

class Surface < Thingy

  @highlight_color = 'surface_highlighted_color'

  def initialize(position1, position2, position3, id: nil, color: 'surface_color')
    super(id)
    @position1 = position1
    @position2 = position2
    @position3 = position3
    @color = color
    @entity = create_entity
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

  def highlight(highlight_color = @highlight_color)
    change_color(highlight_color)
  end

  def un_highlight
    change_color(@color)
  end

  private

  def create_entity
    return @entity if @entity
    entity = Sketchup.active_model.entities.add_face(@position1, @position2, @position3)
    entity.layer = Configuration::TRIANGLE_SURFACES_VIEW
    entity.material = entity.back_material = @color
    entity.edges.each do |edge|
      # hide outline of surfaces, enable line link layer for lines instead of bottles
      edge.hidden = true
    end
    entity
  end
end
