NO_HINGE = 0
A_HINGE = 1
B_HINGE = 2
A_B_HINGE = 3

class ExportElongation
  attr_accessor :hub_id, :other_hub_id, :direction, :length, :hinge_connection

  def initialize(hub_id, other_hub_id, hinge_connection, length, direction)
    @hub_id = hub_id
    @other_hub_id = other_hub_id
    @hinge_connection = hinge_connection
    @length = length
    @direction = direction
  end
end
