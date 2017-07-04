require 'lib/MSPhysics/main.rb'
require 'set'
require 'src/simulation/simulation_helper.rb'

class Animation

  attr_accessor :group, :nodes, :edges, :value, :piston, :upper

  LINE_STIPPLE = '_'.freeze

  def initialize
    @counter = 0
    @frame = 0

    @last_frame = 0
    @last_time = 0


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

    setup

    # connect_tetra2(@nodes)


    @value = nil
    @running = true

    # @last_transformation = @initial_transformation = @group.transformation


    @last_frame_time = Time.now
  end

  def setup
    # create all bodies
    Graph.instance.nodes_and_edges.each do |obj|
      obj.thingy.create_body(@world)
    end

    # create joints
    Graph.instance.edges.values.each do |edge|
      edge.create_joints(@world)
    end

    actuator = Graph.instance.edges.values.find { |edge| edge.link_type == 'actuator' }
    unless actuator.nil?
      @piston = actuator.thingy.piston
      piston_dialog
    end
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

  def joint_between2(parent, child, direction = nil, type = :fixed, group = nil)
    # parent_body = create_body(parent)
    # child_body = create_body(child)

    if direction.nil?
      direction = case child
                    when Node
                      vector(parent, child)
                    when Edge
                      vector(parent, child.other_node(parent))
                  end
    end
    origin = parent.position
    matrix = Geom::Transformation.new(origin, direction)
    joint = case type
              when :fixed
                MSPhysics::Fixed.new(@world, parent_body, matrix, group)
              when :hinge
                MSPhysics::Hinge.new(@world, parent_body, matrix, group)
              when :piston
                MSPhysics::Piston.new(@world, parent_body, matrix, group)
              when :curvy_piston
                MSPhysics::CurvyPiston.new(@world, parent_body, matrix, group)
              when :spring
                MSPhysics::Spring.new(@world, parent_body, matrix, group)
              else
                raise "Type not accepted: #{type}"
            end
    joint.breaking_force = 100000000
    joint.connect(child_body)
    joint.stiffness = 1.0
    joint.friction = 2.0 if type == :hinge
    joint
  end

  def join_between3(parent, child, direction = nil, type = :fixed)
    parent_body = create_body(parent)
    child_body = create_body(child)

    if direction.nil?
      direction = case child
                    when Node
                      vector(parent, child)
                    when Edge
                      vector(parent, child.other_node(parent))
                  end
    end
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

  def vector(node1, node2)
    node1.position.vector_to(node2.position)
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
    lower_upper.delete



    ## single hinge test
    # joint_between2(lower, lower_upper, vector(left, right), :hinge)
    # joint_between2(lower_upper, upper, vector(upper, lower), :fixed)
    # @upper = @bodies[upper]
    # @bodies[lower].static = true


    # joint_between2(lower, lower_upper, vector(left, right), :hinge)
    @piston = joint_between2(lower, upper, vector(lower, upper), :piston)
    @piston.min = 0.01
    @piston.max = 2
    @piston.limits_enabled = true
    @piston.power = 200
    @piston.rate = 0.1
    @piston.controller = 0.6
    # @piston.angular_friction = 10
    # rotate = ->(point, angle) {
    #   rotation_vector = left.position.vector_to(right.position)
    #   Geom::Transformation.rotation(left.position, rotation_vector, angle)
    #   point.transform(angle)
    # }
    # [-20, 0, 20].each do |angle|
    #   point = rotate.call(upper.position, angle)
    #   @piston.add_point(point)
    # end


    # @piston.add_point(lower.position)
    # @piston.add_point(upper.position)





    # joint_between2(lower, lower_upper, :fixed)
    # joint_between2(upper, lower_upper, :fixed)




    joint_between2(lower, left_lower)
    joint_between2(left, left_lower)

    joint_between2(lower, right_lower)
    joint_between2(right, right_lower)

    joint_between2(right, left_right)
    joint_between2(left, left_right)

    joint_between2(left, left_upper, vector(left, right), :hinge)
    joint_between2(upper, left_upper)

    joint_between2(right, right_upper, vector(left, right), :hinge)
    joint_between2(upper, right_upper)

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

  def connect_fixed(node, edge)
    direction = vector(node, edge.other_node(node))
    connect(node, edge, MSPhysics::Fixed, direction)
  end

  def connect(node, edge, klass, direction)
    node.thingy.joint_to(@world, klass, edge.thingy.body, direction)
  end

  def create_cylinder(center, vector, diameter, length)
    translation = Geom::Transformation.translation(center)
    rotation_angle = Geometry.rotation_angle_between(Geometry::Z_AXIS, vector)
    rotation_axis = Geometry.perpendicular_rotation_axis(Geometry::Z_AXIS, vector)
    rotation = Geom::Transformation.rotation(center, rotation_axis, rotation_angle)

    transformation = rotation * translation
    Sketchup.active_model.active_entities.add_instance(@cylinder_def, transformation)
  end

  def create_piston_body(cylinder)
    body = MSPhysics::Body.new(@world, cylinder, :cylinder)
    body.mass = SimulationHelper::PISTON_MASS
    body.collidable = false
    body
  end

  def create_piston_entities(p1, p2)
    center_point = Geom::Point3d.linear_combination(0.5, p1, 0.5, p2)
    v1 = p1.vector_to(center_point)
    v2 = p2.vector_to(center_point)


    c1 = create_cylinder(p1, v1, 1, v1.length * 1.5)
    c2 = create_cylinder(p2, v2, 0.5, v2.length * 1.5)

    [create_piston_body(c1), create_piston_body(c2)]
  end

  def connect_tetra2(nodes)
    upper = nodes.find { |node| !on_ground?(node) }
    lower, left, right = nodes.select { |node| on_ground?(node) }

    left_right = left.edge_to(right)

    left_lower = left.edge_to(lower)
    right_lower = right.edge_to(lower)

    left_upper = left.edge_to(upper)
    right_upper = right.edge_to(upper)

    lower_upper = lower.edge_to(upper)
    lower_upper.delete


    [upper, lower, left, right].each do |node|
      node.thingy.create_body(@world)
    end

    [left_right, left_lower, right_lower, left_upper, right_upper].each do |edge|
      edge.thingy.create_body(@world)
    end


    p1, p2 = create_piston_entities(lower.position, upper.position)
    piston_matrix = Geom::Transformation.new(lower.position, vector(lower, upper))

    lower.thingy.joint_to(@world, MSPhysics::Hinge, p1, vector(left, right))
    @piston = MSPhysics::Piston.new(@world, p1, piston_matrix)
    @piston.connect(p2)
    upper.thingy.joint_to(@world, MSPhysics::Hinge, p2, vector(left, right))

    # @piston = lower.thingy.joint_to(@world, MSPhysics::Piston, upper.thingy.body, vector(lower, upper), lower_upper)
    @piston.power = 2000
    @piston.rate = 0.2

    # @piston.min = 0.01
    # @piston.max = 2
    # @piston.limits_enabled = true



    # fix piston
    # lower.thingy.joint_to(@world, MSPhysics::Fixed, upper.thingy.body, vector(lower, upper))

    # connect_fixed(lower, lower_upper)
    # connect_fixed(upper, lower_upper)


    connect_fixed(lower, left_lower)
    connect_fixed(left, left_lower)

    connect_fixed(lower, right_lower)
    connect_fixed(right, right_lower)

    connect_fixed(right, left_right)
    connect_fixed(left, left_right)

    connect(left, left_upper, MSPhysics::Hinge, vector(left, right))
    connect_fixed(upper, left_upper)

    connect(right, right_upper, MSPhysics::Hinge, vector(left, right))
    connect_fixed(upper, right_upper)

    [left, right, lower].each do |obj|
      obj.thingy.body.static = true
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

  def piston_dialog
    @dialog = UI::HtmlDialog.new(Configuration::HTML_DIALOG)
    file = File.join(File.dirname(__FILE__), 'src/ui/html/piston_slider.html')
    @dialog.set_file(file)
    @dialog.show
    @dialog.add_action_callback('change_piston') do |_context, value|
      value = value.to_f
      @piston.controller = value
    end
  end

  def create_body(graph_obj)
    return @bodies[graph_obj] if @bodies.include?(graph_obj)
    body = case graph_obj
            when Node
              MSPhysics::Body.new(@world, graph_obj.thingy.entity, :sphere)
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
        # body.collidable = false
        body.mass = @edge_mass
    end
    @bodies[graph_obj] = body
    body
  end

  def update_world
    now = Time.now
    @delta = now - @last_frame_time
    @last_frame_time = now
    @world.update(@delta)
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

  def show_force(body, view)
    force = Geom::Vector3d.new(*body.get_force)
    position = body.get_position(1)
    second_position = position + force
    view.line_stipple = LINE_STIPPLE
    view.drawing_color = 'black'
    view.draw_lines(position, second_position)
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
      show_force(body, view)
    end
    # }
    @frame += 1
    if @frame % 20 == 0
      delta_frame = @frame - @last_frame
      now = Time.now.to_f
      delta_time = now - @last_time
      @fps = (delta_frame / delta_time).to_i
      Sketchup.status_text = "Frame: #{@frame}   Time: #{sprintf("%.2f", @world.time)} s   FPS: #{@fps}"
      @last_frame = @frame
      @last_time = now
    end

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


