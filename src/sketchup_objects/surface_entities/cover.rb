# Cover
class Cover < PhysicsSketchupObject
  attr_reader :pods, :body, :joint
  def initialize(first_position, second_position, third_position, normal_vector,
                 pods, id: nil, material: 'wooden_cover')
    super(id, material: material)
    @first_position = first_position
    @second_position = second_position
    @third_position = third_position
    @normal = normal_vector.clone
    @normal.length = Configuration::COVER_THICKNESS
    @pods = pods
    @joint = nil
    @entity = create_entity
    persist_entity
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
    @pods.each(&:delete)
    @pods = []
  end

  # Physics methods
  #
  def create_body(world)
    @body = Simulation.create_body(world, @entity, :convex_hull, @points)
    @body.static = false
    @body.collidable = true
    @body.mass = 10
    @body
  end

  def joint_position
    bb = bounding_box
    bb.center
  end

  def create_joints(world, node, breaking_force)
    body = node.hub.body
    pt = body.group.bounds.center
    # this made structures with covers create energy(!?). First almost no movement and later gets out of control.
    # maybe this has to do with the type of joint, or the joint configurations. (lower stiffness works well)
    # Also the body and the hubs are not touching (pods are in between but no physical object, hidden in simulation)
    @joint = TrussFab::Fixed.new(world, @body, body, pt, @body.group)
    @joint.solver_model = Configuration::JOINT_SOLVER_MODEL
    @joint.stiffness = 0.5
    @joint.breaking_force = breaking_force
  end

  def reset_physics
    super
  end

  private

  def bounding_box
    boundingbox = Geom::BoundingBox.new
    boundingbox.add(@first_node.position, @second_node.position, @third_node.position)
    boundingbox
  end

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
    @points = [first_position, second_position, third_position,
               first_position + @normal, second_position + @normal, third_position + @normal]
    pm.add_polygon(1, 2, 3)
    pm.add_polygon(4, 5, 6)
    pm.add_polygon(1, 2, 5, 4)
    pm.add_polygon(2, 3, 6, 5)
    pm.add_polygon(3, 1, 4, 6)
    smooth_flags = Geom::PolygonMesh::AUTO_SOFTEN |
                   Geom::PolygonMesh::SMOOTH_SOFT_EDGES
    group = Sketchup.active_model.entities.add_group
    group.entities.add_faces_from_mesh(pm, smooth_flags, @material, @material)
    group.layer = Sketchup.active_model
                          .layers[Configuration::TRIANGLE_SURFACES_VIEW]
    group
  end
end
