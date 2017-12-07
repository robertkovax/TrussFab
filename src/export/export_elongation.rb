class ExportElongation
  attr_accessor :hub_id, :other_hub_id, :direction, :length, :is_hinge_connected

  def initialize(hub_id, other_hub_id, is_hinge_connected, length, direction)
    @hub_id = hub_id
    @other_hub_id = other_hub_id
    @is_hinge_connected = is_hinge_connected
    @length = length
    @direction = direction
  end
end
