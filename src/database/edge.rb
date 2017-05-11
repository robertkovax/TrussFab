require 'src/database/graph_object.rb'
require 'src/thingies/link.rb'
require 'src/models/model_storage.rb'

class Edge < GraphObject
  attr_reader :first_node, :second_node
  def initialize(first_node, second_node, model_name, first_elongation_length, second_elongation_length,
                 id: nil, link_type: 'bottle_link')
    @first_node = first_node
    @second_node = second_node
    @model = ModelStorage.instance.models[model_name]
    @first_elongation_length = first_elongation_length
    @second_elongation_length = second_elongation_length
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

  def delete
    super
    @first_node.delete_observer(self)
    @second_node.delete_observer(self)
    @first_node.delete_partner(@second_node)
    @second_node.delete_partner(@first_node)
  end

  def update(symbol, _)
    delete if symbol == :deleted
  end

  private

  def create_thingy(id)
    first_length = @first_elongation_length.zero? ? Configuration::MINIMUM_ELONGATION : @first_elongation_length
    second_length = @second_elongation_length.zero? ? Configuration::MINIMUM_ELONGATION : @second_elongation_length
    model_length = length - first_length - second_length
    shortest_model = @model.longest_model_shorter_than(model_length)
    if @first_elongation_length.zero? && @second_elongation_length.zero?
      @first_elongation_length = @second_elongation_length = (length - shortest_model.length) / 2
    else
      if @first_elongation_length.zero?
        @first_elongation_length = length - shortest_model.length - @second_elongation_length
      end
      if @second_elongation_length.zero?
        @second_elongation_length = length - shortest_model.length - @first_elongation_length
      end
    end
    Link.new(@first_node.position,
             @second_node.position,
             shortest_model.definition,
             @first_elongation_length,
             @second_elongation_length,
             id: id)
  end

  def register_observers
    @first_node.add_observer(self)
    @second_node.add_observer(self)
  end
end
