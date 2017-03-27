require ProjectHelper.database_directory + '/graph_object.rb'
require ProjectHelper.database_directory + '/hub.rb'

class Node < GraphObject
  attr_reader :position, :partners

  def initialize position
    @position = position
    @partners = Hash.new
    super nil
  end

  private
  def create_thingy id
    @thingy = Hub.new id, @position
  end
end