class Cover < Thingy
  def initialize(first_position, second_position, third_position, normal_vector, id: nil, material: 'wooden_cover')
    super(id)
    @first_position = first_position
    @second_position = second_position
    @third_position = third_position
    @normal = normal_vector.clone
    @normal.length = Configuration::COVER_THICKNESS
    @material = material
    @entity = create_entity
  end

  def highlight
    # do nothing
  end

  def un_highlight
    # do nothing
  end

  private

  def create_entity
    pm = Geom::PolygonMesh.new
    pm.add_point @first_position
    pm.add_point @second_position
    pm.add_point @third_position
    pm.add_point @first_position + @normal
    pm.add_point @second_position + @normal
    pm.add_point @third_position + @normal
    pm.add_polygon(1, 2, 3)
    pm.add_polygon(4, 5, 6)
    pm.add_polygon(1, 2, 5, 4)
    pm.add_polygon(2, 3, 6, 5)
    pm.add_polygon(3, 1, 4, 6)
    smooth_flags = Geom::PolygonMesh::AUTO_SOFTEN | Geom::PolygonMesh::SMOOTH_SOFT_EDGES
    group = Sketchup.active_model.entities.add_group
    group.entities.add_faces_from_mesh(pm, smooth_flags, @material, @material)
    group.layer = Sketchup.active_model.layers[Configuration::TRIANGLE_SURFACES_VIEW]
    group
  end
end