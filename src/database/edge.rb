require 'set'
require 'src/database/graph_object.rb'
require 'src/sketchup_objects/link.rb'
require 'src/sketchup_objects/actuator_link.rb'
require 'src/sketchup_objects/spring_link.rb'
require 'src/sketchup_objects/generic_link.rb'
require 'src/sketchup_objects/pid_controller.rb'
require 'src/models/model_storage.rb'
require 'src/simulation/thingy_rotation.rb'
require 'src/configuration/configuration.rb'

# Edge
class Edge < GraphObject
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
                 bottle_type: nil,
                 id: nil, link_type: 'bottle_link')
    @first_node = first_node
    @second_node = second_node
    @first_node.add_incident(self)
    @second_node.add_incident(self)
    @bottle_models = ModelStorage.instance.models['hard']
    @bottle_type = bottle_type
    update_bottle_type if bottle_type.nil?
    @link_type = link_type
    edge_id = id.nil? ? IdManager.instance.generate_next_tag_id('edge') : id
    super(edge_id)
  end

  def link
    @sketchup_object
  end

  def link_type=(type)
    return unless type != @link_type
    @link_type = type
    recreate_sketchup_object
  end

  def dynamic?
    link.is_a?(PhysicsLink)
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
    link.create_joints(world, @first_node, @second_node, breaking_force)
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
      link.first_node = new_node
    elsif current_node == @second_node
      @second_node = new_node
      link.second_node = new_node
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
    return [] if triangles.empty?

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

  def update_parametric_spring_model
    link.recreate_children
  end

  def update_sketchup_object
    if @link_type == 'bottle_link'
      update_bottle_type unless @@retain_bottle_types

      model = @bottle_models.models[@bottle_type]
      link.model = model
    end

    if @link_type == 'spring'
      update_parametric_spring_model
    end

    link.update_positions(@first_node.position, @second_node.position)
  end

  def next_longer_length
    length * 1.1
  end

  def next_shorter_length
    length * 0.9
  end

  def first_elongation_length
    link.first_elongation_length
  end

  def second_elongation_length
    link.second_elongation_length
  end

  def inspect
    "Edge #{@id} (#{@first_node.id}, #{@second_node.id}) (doublecount: #{@sketchup_object.double_counter})"
  end

  def reset
    recreate_sketchup_object

    return unless @link_type == 'bottle_link'
    link.change_color(Configuration::BOTTLE_COLOR)
  end

  def bottle_length_short_name
    @bottle_models.models[@bottle_type].short_name
  end

  private

  def create_sketchup_object(id)
    sketchup_object =
      case @link_type
      when 'bottle_link'
        update_bottle_type if @bottle_type.empty?

        Link.new(@first_node,
                 @second_node,
                 self,
                 Configuration::STANDARD_BOTTLES,
                 bottle_name: @bottle_type,
                 id: id)
      when 'actuator'
        ActuatorLink.new(@first_node,
                         @second_node,
                         self,
                         id: id)
      when 'spring'
        SpringLink.new(@first_node,
                       @second_node,
                       self,
                       id: id)
      when 'generic'
        GenericLink.new(@first_node,
                        @second_node,
                        self,
                        id: id)
      when 'pid_controller'
        PidController.new(@first_node,
                          @second_node,
                          self,
                          id: id)
      else
        raise "Unkown link type: #{@link_type}"
      end

    sketchup_object
  end
end
