require ProjectHelper.database_directory + '/graph_object.rb'
require ProjectHelper.database_directory + '/hub.rb'
require 'observer'

class Node < GraphObject
  include Observable

  attr_reader :position, :partners

  def initialize position, id: nil
    @deleting
    @position = position
    @partners = Hash.new
    @observer = Set.new
    super id
  end

  def distance point
    @position.distance point
  end

  def add_partner node, edge
    partners[node.id] = {node: node, edge: edge}
  end

  def delete_partner node
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

  private
  def create_thingy id
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
end