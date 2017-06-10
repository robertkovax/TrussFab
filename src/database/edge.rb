require 'set'
require 'src/database/graph_object.rb'
require 'src/thingies/link.rb'
require 'src/models/model_storage.rb'

class Edge < GraphObject
  attr_reader :first_node, :second_node
  attr_accessor :desired_length

  def initialize(first_node, second_node, model_name: 'hard', id: nil, link_type: 'bottle_link')
    @first_node = first_node
    @second_node = second_node
    @first_node.add_incident(self)
    @second_node.add_incident(self)
    @model_name = model_name
    super(id)
  end

  def distance(point)
    Geometry.dist_point_to_segment(point, segment)
  end

  def other_node(node)
    if node == @first_node
      @second_node
    elsif node == @second_node
      @first_node
    else
      raise 'Node not part of this Edge'
    end
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

  def segment
    [first_node.position, second_node.position]
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

  private

  def create_thingy(id)
    Link.new(@first_node.position,
             @second_node.position,
             @model_name,
             id: id)
  end
end
