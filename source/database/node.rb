require ProjectHelper.database_directory + '/graph_object.rb'
require ProjectHelper.database_directory + '/hub.rb'

class Node < GraphObject
  attr_reader :position, :partners

  def initialize position, id: nil
    @position = position
    @partners = Hash.new
    super id
  end

  private
  def create_thingy id
    @thingy = Hub.new @position, id: id
  end
end