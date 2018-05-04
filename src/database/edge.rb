require 'set'
require 'src/database/graph_object.rb'
require 'src/thingies/link.rb'
require 'src/thingies/actuator_link.rb'
require 'src/thingies/spring_link.rb'
require 'src/thingies/generic_link.rb'
require 'src/models/model_storage.rb'
require 'src/simulation/thingy_rotation.rb'
require 'src/configuration/configuration'

# Edge
class Edge < GraphObject
  attr_accessor :piston_group
  attr_reader :first_node, :second_node, :link_type, :bottle_type

  @@retain_bottle_types = false

  def self.enable_bottle_freeze
    @@retain_bottle_types = true
  end

  def self.disable_bottle_freeze
    @@retain_bottle_types = false
  end

  def initialize(first_node,
                 second_node,
                 bottle_type: Configuration::BIG_BIG_BOTTLE_NAME,
                 id: nil, link_type: 'bottle_link')
    @first_node = first_node
    @second_node = second_node
    @first_node.add_incident(self)
    @second_node.add_incident(self)
    @bottle_models = ModelStorage.instance.models['hard']
    @bottle_type = bottle_type
    @link_type = link_type
    edge_id = id.nil? ? IdManager.instance.generate_next_tag_id('edge') : id
    @piston_group = -1
    super(edge_id)
  end

  def link_type=(type)
    return unless type != @link_type
    @link_type = type
    recreate_thingy
  end

  def dynamic?
    thingy.is_a?(PhysicsLink)
  end

  def distance(point)
    # offset to take ball_hub_radius into account
    first_point = position.offset(direction, Configuration::BALL_HUB_RADIUS / 2)
    second_point = end_position.offset(direction.reverse,
                                       Configuration::BALL_HUB_RADIUS / 2)
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

  def create_joints(world, breaking_force)
    @thingy.create_joints(world, @first_node, @second_node, breaking_force)
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
    [@first_node, @second_node]
  end

  def fixed?
    first_node.fixed? || second_node.fixed?
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
    sorted_triangles.product(sorted_triangles)
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
    first_connected = @first_node.incidents - [self]
    second_connected = @second_node.incidents - [self]
    first_connected + second_connected
  end

  def delete
    super
    @first_node.delete_incident(self)
    @second_node.delete_incident(self)

    adjacent_triangles.each(&:delete)
  end

  def update_bottle_type
    model_length = length - 2 * Configuration::MINIMUM_ELONGATION
    model = @bottle_models.longest_model_shorter_than(model_length)
    @bottle_type = model.name
  end

  def update_thingy
    if @link_type == 'bottle_link'
      update_bottle_type unless @@retain_bottle_types

      model = @bottle_models.models[@bottle_type]
      @thingy.model = model
    end

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

  def inspect
    "Edge #{@id} (#{@first_node.id}, #{@second_node.id})"
  end

  def reset
    recreate_thingy

    return unless @link_type == 'bottle_link'
    @thingy.change_color(Configuration::BOTTLE_COLOR)
  end

  private

  def create_thingy(id)
    thingy = case @link_type
             when 'bottle_link'
               update_bottle_type if @bottle_type.empty?

               Link.new(@first_node,
                        @second_node,
                        Configuration::STANDARD_BOTTLES,
                        bottle_name: @bottle_type,
                        id: id)
             when 'actuator'
               ActuatorLink.new(@first_node,
                                @second_node,
                                id: id)
             when 'spring'
               SpringLink.new(@first_node,
                              @second_node,
                              id: id)
             when 'generic'
               GenericLink.new(@first_node,
                               @second_node,
                               id: id)
             else
               raise "Unkown link type: #{@link_type}"
             end
    thingy
  end
end
