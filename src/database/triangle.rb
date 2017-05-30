require 'src/database/graph_object.rb'
require 'src/thingies/surface.rb'

class Triangle < GraphObject
  attr_reader :first_node, :second_node, :third_node

  def initialize(first_node, second_node, third_node, id: nil)
    @first_node = first_node
    @second_node = second_node
    @third_node = third_node
    @deleted = false
    super(id)
    register_observers
  end

  def normal_towards_user
    view_direction = Sketchup.active_model.active_view.camera.direction
    if normal.angle_between(view_direction) > Math::PI / 2
      normal
    else
      normal.reverse
    end
  end

  def normal
    vector1 = @first_node.position.vector_to(@second_node.position)
    vector2 = @first_node.position.vector_to(@third_node.position)
    vector1.cross(vector2)
  end

  def position
    center
  end

  def center
    Geometry.triangle_incenter(@first_node.position,
                               @second_node.position,
                               @third_node.position)
  end

  def distance(point)
    center.distance(point)
  end

  def update(symbol, source)
    if symbol == :deleted && !@deleted
      @thingy.delete_edges(source.position)
      delete
    end
  end

  def nodes
    [first_node, second_node, third_node]
  end

  def nodes_ids    
    [first_node.id, second_node.id, third_node.id]
  end
  
  def nodes_ids_towards_user
    # this is ugly! this is made to be able to recreate the surface with the
    # same direction by aranging the ids in the right order. This should be
    # done differently at some point
    if normal_towards_user == normal
      return [first_node.id, third_node.id, second_node.id]
    else
      return nodes_ids
    end
  end

  def delete
    @deleted = true
    super
    nodes.each do |node|
      node.delete if !node.nil?
    end
  end

  private

  def create_thingy(id)
    Surface.new(@first_node.position,
                @second_node.position,
                @third_node.position,
                id: id)
  end

  def delete_observers
    @first_node.delete_observer(self)
    @second_node.delete_observer(self)
    @third_node.delete_observer(self)
  end

  def register_observers
    @first_node.add_observer(self)
    @second_node.add_observer(self)
    @third_node.add_observer(self)
  end

end
