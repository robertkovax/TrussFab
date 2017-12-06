class ExportElongation
  attr_accessor :hub_id, :other_hub_id, :direction, :l1, :l2, :l3, :is_hinge_connected

  def initialize(hub_id, other_hub_id, is_hinge_connected, l1, l2, l3, direction)
    @hub_id = hub_id
    @other_hub_id = other_hub_id
    @is_hinge_connected = is_hinge_connected
    @l1 = l1 # if no hinge connected, this is the length
    @l2 = l2
    @l3 = l3
    @direction = direction
  end
end
