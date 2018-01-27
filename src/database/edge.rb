require 'set'
require 'src/database/graph_object.rb'
require 'src/thingies/link.rb'
require 'src/thingies/actuator_link.rb'
require 'src/models/model_storage.rb'
require 'src/simulation/joints'
require 'src/simulation/thingy_rotation.rb'

class Edge < GraphObject
  attr_reader :first_node, :second_node, :link_type

  def initialize(first_node, second_node, model_name: 'hard', id: nil, link_type: 'bottle_link')
    @first_node = first_node
    @second_node = second_node
    @first_node.add_incident(self)
    @second_node.add_incident(self)
    @model_name = model_name
    @link_type = link_type
    super(id)
  end

  def link_type=(type)
    if type != @link_type
      @link_type = type
      recreate_thingy
    end
  end

  def distance(point)
    # offset to take ball_hub_radius into account
    first_point = position.offset(direction, Configuration::BALL_HUB_RADIUS / 2)
    second_point = end_position.offset(direction.reverse, Configuration::BALL_HUB_RADIUS / 2)
    segment = [first_point, second_point]
    Geometry.dist_point_to_segment(point, segment)
  end

  def other_node(node)
    if node == @first_node
      @second_node
    elsif node == @second_node
      @first_node
    else
      raise "Node not part of this Edge: #{node}"
    end
  end

  def shared_node(other_edge)
    intersection = nodes & other_edge.nodes
    return false if intersection.empty?
    intersection[0]
  end

  def first_node?(node)
    node == @first_node
  end

  def create_joints(world)
    @thingy.create_joints(world, first_node, second_node)
  end

  def create_ball_joints(world)
    @thingy.create_ball_joints(world, first_node, second_node)
  end

  def position
    @first_node.position
  end

  def end_position
    position + direction
  end

  def direction
    @first_node.position.vector_to(@second_node.position)
  end

  def nodes
    [first_node, second_node]
  end

  def fixed?
    first_node.fixed? && second_node.fixed?
  end

  def exchange_node(current_node, new_node)
    if current_node == @first_node
      @first_node = new_node
    elsif current_node == @second_node
      @second_node = new_node
    else
      raise "#{current_node} not in nodes"
    end
  end

  def segment
    [position, end_position]
  end

  def mid_point
    p1 = @first_node.position
    p2 = @second_node.position
    Geom::Point3d.linear_combination(0.5, p1, 0.5, p2)
  end

  def adjacent_triangles
    @first_node.adjacent_triangles & @second_node.adjacent_triangles
  end

  def sorted_adjacent_triangle_pairs
    sorted_triangles = sorted_adjacent_triangles
    sorted_triangles << sorted_triangles.first
    sorted_triangles.each_cons(2)
  end

  def sorted_adjacent_triangles
    triangles = adjacent_triangles
    ref_vector = mid_point.vector_to(triangles[0].other_node_for(self).position)
    normal = direction.normalize
    triangles.sort_by do |t|
      v = mid_point.vector_to(t.other_node_for(self).position)
      Geometry.angle_around_normal(ref_vector, v, normal)
    end
  end

  def length
    @first_node.position.distance(@second_node.position)
  end

  def opposite(node)
    return @second_node if node == @first_node
    return @first_node if node == @second_node
    nil
  end

  def connected_component
    edges_to_process = [self]
    seen = Set.new([self])

    until edges_to_process.empty?
      edge = edges_to_process.pop
      edge.incidents.each do |other_edge|
        unless seen.include?(other_edge)
          edges_to_process.push(other_edge)
          seen.add(other_edge)
        end
      end
    end
    seen
  end

  def incidents
    first_connected = first_node.incidents - [self]
    second_connected = second_node.incidents - [self]
    first_connected + second_connected
  end

  def delete
    super
    @first_node.delete_incident(self)
    @second_node.delete_incident(self)
  end

  def move
    @thingy.update_positions(@first_node.position, @second_node.position)
  end

  def next_longer_length
    length * 1.1
  end

  def next_shorter_length
    length * 0.9
  end

  def first_elongation_length
    @thingy.first_elongation_length
  end

  def second_elongation_length
    @thingy.second_elongation_length
  end

  private

  def create_thingy(id)
    case @link_type
    when 'bottle_link'
      Link.new(@first_node,
               @second_node,
               @model_name,
               id: id)
    when 'actuator'
      ActuatorLink.new(@first_node,
                       @second_node,
                       id: id)
    else
      raise "Unkown link type: #{@link_type}"
    end
  end
end
