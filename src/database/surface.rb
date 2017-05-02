require 'src/database/thingy.rb'

class Surface < Thingy
  def initialize(position1, position2, position3, id: nil, color: 'surface_color')
    @position1 = position1
    @position2 = position2
    @position3 = position3
    @entities = nil
    @color = color
    super id
  end

  def delete
    super
    @entities.each do |entity|
      entity.erase! unless entity.nil? || entity.deleted?
    end
  end

  private

  def create_entity
    @entity = Sketchup.active_model.entities.add_face(@position1, @position2, @position3)
    @entity.layer = Configuration::TRIANGLE_SURFACES_VIEW
    @entity.material = @entity.back_material = @color
    @entities = @entity.edges
    @entities.each do |entity|
      # hide outline of surfaces, enable line link layer for lines instead of bottles
      entity.hidden = true
    end
  end
end
