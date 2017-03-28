require ProjectHelper.database_directory + '/thingy.rb'

class Surface < Thingy
  def initialize position1, position2, position3, id: nil
    @position1 = position1
    @position2 = position2
    @position3 = position3
    @entities = nil
    super id
  end

  private
  def create_entity
    @entity = Sketchup.active_model.entities.add_face @position1, @position2, @position3
    @entity.layer = Configuration::TRIANGLE_SURFACES_VIEW
    @entity.material = @entity.back_material = 'surface_color'
    @entities = @entity.edges
  end
end