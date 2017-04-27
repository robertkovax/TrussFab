require ProjectHelper.database_directory + '/graph_object.rb'
require ProjectHelper.database_directory + '/hub.rb'
require 'observer'

class Node < GraphObject
  include Observable

  attr_reader :position, :partners

  def initialize(position, id: nil)
    @deleting
    @position = position
    @partners = {}
    @observer = Set.new
    super id
  end

  def distance(point)
    @position.distance point
  end

  def add_partner(node, edge)
    partners[node.id] = { node: node, edge: edge }
  end

  def delete_partner(node)
    @partners.delete(node.id) unless partners[node.id].nil?
    return true if @deleting # prevent dangling check when deleting node
    delete if dangling?
  end

  def delete
    @deleting = true
    super
    changed
    notify_observers :deleted
    delete_observers
  end

  def dangling?
    partners.empty?
  end

  def partners_include?(node_or_partner)
    result = false
    result = partners_include_node? node_or_partner if node_or_partner.is_a? Node
    result = partners_include_edge? node_or_partner if node_or_partner.is_a? Edge
    result
  end

  private

  def create_thingy(id)
    @thingy = Hub.new @position, id: id
  end

  def delete_thingy
    @thingy.delete
    @thingy = nil
  end

  def delete_partners
    partners.each_value do |partner|
      partners.delete partner[:edge] unless partner[:edge].nil?
    end
  end

  def partners_include_node?(node)
    @partners.each_value do |partner|
      return true if partner[:node] == node
    end
    false
  end

  def partners_include_edge?(edge)
    @partners.each_value do |partner|
      return true if partner[:edge] == edge
    end
    false
  end
end
