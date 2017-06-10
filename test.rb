require 'lib/MSPhysics/main.rb'
require 'set'

class Animation

  def initialize
    @counter = 0
    @node = Graph.instance.nodes.values[0]
    @edge = Graph.instance.edges.values[0]

    @world = MSPhysics::World.new
    # @node_body = create_body_for(@node)
    # @edge_body = create_body_for(@edge)


    @nodes_bodies = Hash[Graph.instance.nodes.map do |_, node|
      [node, create_body_for(node)]
    end]

    @node_body = @nodes_bodies.values[0]

    connect_all_fixed(Graph.instance.nodes.values)

    @last_frame_time = Time.now
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
                raise NotImplementedError
              else
                raise "Type not accepted: #{type}"
            end
    joint.connect(@nodes_bodies[node2])
    joint
  end

  def create_body_for(graph_obj)
    case graph_obj
      when Node
        MSPhysics::Body.new(@world, graph_obj.thingy.entity, :sphere)
      when Edge
        MSPhysics::Body.new(@world, graph_obj.thingy.line.entity, :null)
      else
        raise "Unsupported graph object: #{graph_obj}"
    end
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

  def nextFrame(_view)
    @node_body.set_force([0,0,1])

    log_time('update world') {
      update_world
    }

    log_time('update node positions') {
      Graph.instance.nodes.values.each do |node|
        body = @nodes_bodies[node]
        position = nil
        log_time('get position') {
          position = body.get_position
        }
        log_time('move node') {
          node.move(position)
        }
      end
    }

    # puts MSPhysics::Newton::Body.get_force(@body_address)
    # puts position
    @counter += 1
    @counter <= 10
  end

end

Sketchup.active_model.active_view.animation = Animation.new