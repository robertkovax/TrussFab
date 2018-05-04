NO_HINGE = 0
A_HINGE = 1
B_HINGE = 2
A_B_HINGE = 3

# Exports elongation to SCAD file
class ExportElongation
  attr_accessor :hub_id, :other_hub_id, :direction,
                :l1, :l2, :l3, :hinge_connection

  def initialize(hub_id, other_hub_id, hinge_connection, l1, l2, l3, direction)
    @hub_id = hub_id
    @other_hub_id = other_hub_id
    @hinge_connection = hinge_connection
    @l1 = l1
    @l2 = l2
    @l3 = l3
    @direction = direction
  end

  def total_length
    @l1 + @l2 + @l3
  end
end
