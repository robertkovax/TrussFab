require 'src/database/graph_object.rb'
require 'src/thingies/hub.rb'
require 'observer'

class Node < GraphObject
  include Observable

  attr_reader :position, :partners

  def initialize(position, id: nil)
    @deleting = false
    @position = position
    @partners = {}
    @observer = Set.new
    super(id)
  end

  def distance(point)
    @position.distance(point)
  end

  def add_partner(node, edge)
    @partners[node.id] = { node: node, edge: edge }
  end

  def delete_partner(node)
    @partners.delete(node.id) unless @partners[node.id].nil?
    return true if @deleting # prevent dangling check when deleting node
    delete if dangling?
  end

  def delete
    super
    changed
    notify_observers(:deleted, self)
    delete_observers
  end

  def dangling?
    @partners.empty?
  end

  def partners_include?(node_or_partner)
    if node_or_partner.is_a?(Node)
      partners_include_node?(node_or_partner)
    elsif node_or_partner.is_a?(Edge)
      partners_include_edge?(node_or_partner)
    else
      false
    end
  end

  private

  def create_thingy(id)
    Hub.new(@position, id: id)
  end

  def delete_thingy
    @thingy.delete
    @thingy = nil
  end

  def delete_partners
    @partners.each_value do |partner|
      @partners.delete(partner[:edge]) unless partner[:edge].nil?
    end
  end

  def partners_include_node?(node)
    @partners.values.any? { |partner| partner[:node] == node }
  end

  def partners_include_edge?(edge)
    @partners.values.any? { |partner| partner[:edge] == edge }
  end
end
