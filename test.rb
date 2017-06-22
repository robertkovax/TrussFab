require 'lib/MSPhysics/main.rb'
require 'set'

class Animation

  attr_accessor :group, :nodes, :edges, :value, :piston

  def initialize
    @counter = 0

    @edge_mass = 10.0
    @node_mass = 1.0

    @nodes = Graph.instance.nodes.values
    @edges = Graph.instance.edges.values

    @node = @nodes[0]
    @edge = @edges[0]

    @world = MSPhysics::World.new
    # @world.set_gravity(0, 0, 0)
    @bodies = {}

    @ground_body = add_ground
    # @node_body = create_body_for(@node)
    # @edge_body = create_body_for(@edge)

    # @nodes_bodies = create_bodies(Graph.instance.nodes.values)
    # @node_body = @nodes_bodies.values[0]
    # connect_all_fixed(Graph.instance.nodes.values)

    # @transformation = Geom::Transformation.new
    # connected_nodes = connected_component(@node)
    # @group = create_group(connected_nodes)
    # @group_body = create_body(@group)

    connect_tetra(@nodes)

    # [@nodes, @edges].flatten.each do |graph_obj|
    #   create_body(graph_obj)
    # end


    @value = nil
    @running = true

    # @last_transformation = @initial_transformation = @group.transformation


    @last_frame_time = Time.now
  end

  def add_ground
    group = Sketchup.active_model.entities.add_group()
    x = y = 10_000
    z = -1
    pts = []
    pts[0] = [-x, -y, z]
    pts[1] = [x, -y, z]
    pts[2] = [x, y, z]
    pts[3] = [-x, y, z]
    face = group.entities.add_face(pts)
    face.pushpull(-1)
    face.visible = false
    body = create_body(group)
    body.static = true
    body
  end

  def all_entities(nodes)
    edges = nodes.flat_map(&:incidents).to_set
    triangles = nodes.flat_map(&:adjacent_triangles).to_set

    graph_objects = [*nodes, *edges, *triangles]

    graph_objects.flat_map { |g| g.thingy.all_entities }
  end

  def create_group(nodes)
    Sketchup.active_model.entities.add_group(all_entities(nodes).to_a)
  end

  def connected_component(node)
    queue = [@nodes[0]]
    seen = Set.new

    until queue.empty?
      node = queue.pop
      seen.add(node)
      node.adjacent_nodes.each do |other_node|
        unless seen.include?(other_node)
          queue.push(other_node)
        end
      end
    end
    seen
  end

  def group_for(nodes)
    edges = nodes.flat_map do |node|
      node.incidents.select { |edge| nodes.include?(edge.other_node(node)) }
    end.to_set

    graph_objects = [*nodes, *edges]

    graph_objects.flat_map { |g| g.thingy.all_entities }
  end

  def joint_between2(parent, child, type = :fixed, group = nil)
    parent_body = create_body(parent)
    child_body = create_body(child)

    origin = parent.position
    direction = case child
                  when Node
                    origin.vector_to(child.position)
                  when Edge
                    origin.vector_to(child.other_node(parent).position)
                  else
                    raise 'unsupported obj'
                end
    matrix = Geom::Transformation.new(origin, direction)
    joint = case type
              when :fixed
                MSPhysics::Fixed.new(@world, parent_body, matrix, group)
              when :hinge
                MSPhysics::Hinge.new(@world, parent_body, Geom::Transformation.new(origin, Geom::Vector3d.new(0,0,1)), group)
              when :piston
                MSPhysics::Piston.new(@world, parent_body, matrix, group)
              when :spring
                MSPhysics::Spring.new(@world, parent_body, matrix, group)
              when :curvy_piston
                MSPhysics::CurvyPiston.new(@world, parent_body, matrix, group)
              else
                raise "Type not accepted: #{type}"
            end
    joint.connect(child_body)
    joint.stiffness = 1
    joint.friction = 10.0 if type == :hinge
    joint
  end

  def fix_to_ground(graph_obj)
    parent_body = @ground_body
    child_body = create_body(graph_obj)

    matrix = Geom::Transformation.new(graph_obj.position, Geom::Vector3d.new(0, 0, 1))
    joint = MSPhysics::Fixed.new(@world, parent_body, matrix, nil)
    joint.connect(child_body)
    joint
  end

  def on_ground?(node)
    node.position.z == 0
  end

  def connect_tetra(nodes)
    upper = nodes.find { |node| !on_ground?(node) }
    lower, left, right = nodes.select { |node| on_ground?(node) }

    left_right = left.edge_to(right)

    left_lower = left.edge_to(lower)
    right_lower = right.edge_to(lower)

    left_upper = left.edge_to(upper)
    right_upper = right.edge_to(upper)

    lower_upper = lower.edge_to(upper)
    lower_upper.thingy.highlight



    @piston = joint_between2(lower, upper, :curvy_piston, lower_upper.thingy.group)
    # @piston.min = 0.01
    # @piston.max = 2
    # @piston.limits_enabled = true
    # @piston.power = 2
    @piston.rate = 0.1
    @piston.angular_friction = 10

    rotate = ->(point, angle) {
      rotation_vector = left.position.vector_to(right.position)
      Geom::Transformation.rotation(left.position, rotation_vector, angle)
      point.transform(angle)
    }

    @bodies[lower].static = true

    # @piston.add_point(lower.position)
    # @piston.add_point(upper.position)

    [-20, -10, 0, 10, 20].each do |angle|
      point = rotate.call(upper.position, angle)
      @piston.add_point(point)
    end



    # joint_between2(lower, lower_upper, :fixed)
    # joint_between2(upper, lower_upper, :fixed)




    # joint_between2(lower, left_lower, :fixed)
    # joint_between2(left, left_lower, :fixed)
    #
    # joint_between2(lower, right_lower, :fixed)
    # joint_between2(right, right_lower, :fixed)
    #
    # joint_between2(right, left_right, :fixed)
    # joint_between2(left, left_right, :fixed)
    #
    # joint_between2(left, left_upper, :hinge)
    # joint_between2(upper, left_upper, :fixed)
    #
    # joint_between2(right, right_upper, :hinge)
    # joint_between2(upper, right_upper, :fixed)

    # @piston = joint_between2(lower, upper, :piston)
    # @piston.power = 3
    # joint_between2(upper, left, :hinge)
    # joint_between2(upper, right, :hinge)
    #
    # joint_between2(lower, left, :fixed)
    # joint_between2(lower, right, :fixed)
    #
    # joint_between2(left, right, :fixed)

    [left, right, lower].each do |obj|
      fix_to_ground(obj)
    end
  end

  def connect_all_fixed(nodes)
    queue = [nodes[0]]
    nodes = Set.new(nodes)
    seen = Set.new

    until queue.empty?
      node = queue.pop
      seen.add(node)
      node.adjacent_nodes.each do |other_node|
        if !seen.include?(other_node) && nodes.include?(node)
          joint_between(node, other_node, :fixed)
          queue.push(other_node)
        end
      end
    end
  end

  def joint_between(node1, node2, type=:fixed)
    origin = node1.position
    direction = node1.position.vector_to(node2.position)
    matrix = Geom::Transformation.new(origin, direction)
    joint = case type
              when :fixed
                MSPhysics::Fixed.new(@world, @nodes_bodies[node1], matrix)
              when :hinge
                MSPhysics::Hinge.new(@world, @nodes_bodies[node1], matrix)
              when :piston
                MSPhysics::Piston.new(@world, @nodes_bodies[node1], matrix)
              else
                raise "Type not accepted: #{type}"
            end
    joint.connect(@nodes_bodies[node2])
    joint
  end

  def create_bodies(nodes)
    Hash[nodes.map { |node| [node, create_body(node)] }]
  end

  def create_body(graph_obj)
    return @bodies[graph_obj] if @bodies.include?(graph_obj)
    body = case graph_obj
            when Node
              MSPhysics::Body.new(@world, graph_obj.thingy.entity, :convex_hull)
            when Edge
              MSPhysics::Body.new(@world, graph_obj.thingy.group, :convex_hull)
            when Sketchup::Entity
              MSPhysics::Body.new(@world, graph_obj, :convex_hull)
            else
              raise "Unsupported graph object: #{graph_obj}"
           end
    case graph_obj
      when Node
        body.mass = @node_mass
      when Edge
        body.collidable = false
        body.mass = @edge_mass
    end
    @bodies[graph_obj] = body
    body
  end

  def update_world
    now = Time.now
    delta = now - @last_frame_time
    @last_frame_time = now
    @world.update(delta)
  end

  def log_time(msg = nil, &block)
    before = Time.now
    yield
    after = Time.now
    span = after - before
    print msg + ' - ' unless msg.nil?
    puts span
  end

  def piston_controller=(value)
    @piston.controller = value
  end

  def nextFrame(view)
    # force on whole body
    # @group_body.set_force([0, 0, 1000])

    # force applied at specific point
    # point = @node.position
    # @group_body.add_point_force(point, [0, 0, 100])


    # log_time('update world') {
    update_world
    # }

    # log_time('update group position') {
    MSPhysics::Body.all_bodies.each do |body|
      body.group.move!(body.get_matrix) if body.matrix_changed?
    end
    # }
    view.show_frame
    @running
  end

  def halt
    @running = false
  end

  def stop
    # @nodes.each do |node|
    #   node.move(@transformation * node.position)
    # end

  end

end

def animate
  animation = Animation.new
  Sketchup.active_model.active_view.animation = animation
  animation
end


