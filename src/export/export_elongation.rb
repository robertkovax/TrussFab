class ExportElongation
  attr_accessor :direction, :l1, :l2, :l3, :is_hinge_connected

  def initialize(is_hinge_connected, l1, l2, l3, direction)
    @is_hinge_connected = is_hinge_connected
    @l1 = l1 # if no hinge connected, this is the length
    @l2 = l2
    @l3 = l3
    @direction = direction
  end
end
