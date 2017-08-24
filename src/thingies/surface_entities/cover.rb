class Cover < Thingy
  attr_reader :pods
  def initialize(first_position, second_position, third_position, normal_vector,
                 pods, id: nil, material: 'wooden_cover')
    super(id, material: material)
    @first_position = first_position
    @second_position = second_position
    @third_position = third_position
    @normal = normal_vector.clone
    @normal.length = Configuration::COVER_THICKNESS
    @pods = pods
    @entity = create_entity
  end

  def center
    Geometry.triangle_incenter(@first_position,
                               @second_position,
                               @third_position)
  end

  def update_positions(first_position, second_position, third_position)
    @first_position = first_position
    @second_position = second_position
    @third_position = third_position
    delete_entity
    @entity = create_entity
  end

  def exchange_pod(old_pod, new_pod)
    @pods.delete(old_pod)
    @pods << new_pod
  end

  def distance(point)
    center.distance(point)
  end

  def delete
    super
    adjacent_cover_pods = @pods.flat_map do |p|
      p.node.adjacent_triangles.map(&:cover)
    end.compact.flat_map(&:pods)

    (@pods - adjacent_cover_pods).each(&:delete)
    @pods = []
  end

  private

  def create_entity
    offset_vector = @normal.clone
    pod_length = ModelStorage.instance.models['pod'].length
    offset_vector.length = pod_length
    first_position = @first_position + offset_vector
    second_position = @second_position + offset_vector
    third_position = @third_position + offset_vector

    pm = Geom::PolygonMesh.new
    pm.add_point first_position
    pm.add_point second_position
    pm.add_point third_position
    pm.add_point first_position + @normal
    pm.add_point second_position + @normal
    pm.add_point third_position + @normal
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
