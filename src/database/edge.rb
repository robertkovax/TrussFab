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
    @model_name = model_name
    super(id)
    @first_node.add_partner(@second_node, self)
    @second_node.add_partner(@first_node, self)
    register_observers
  end

  def distance(point)
    Geometry.dist_point_to_segment(point, segment)
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

  def connected_edges
    edges_to_process = [self]
    seen = Set.new([self])

    until edges_to_process.empty?
      edge = edges_to_process.pop
      edge.directly_connected_edges.each do |other_edge|
        unless seen.include?(other_edge)
          edges_to_process.push(other_edge)
          seen.add(other_edge)
        end
      end
    end
    seen
  end

  def directly_connected_edges
    first_connected = first_node.partners.values.map { |partner| partner[:edge] } - [self]
    second_connected = second_node.partners.values.map { |partner| partner[:edge] } - [self]
    first_connected + second_connected
  end

  def delete
    super
    @first_node.delete_observer(self)
    @second_node.delete_observer(self)
    @first_node.delete_partner(@second_node)
    @second_node.delete_partner(@first_node)
  end

  def move
    @thingy.update_positions(@first_node.position, @second_node.position)
  end

  def update(symbol, _)
    if symbol == :deleted
      delete
    elsif symbol == :moved
      move
    end
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

  def register_observers
    @first_node.add_observer(self)
    @second_node.add_observer(self)
  end
end
