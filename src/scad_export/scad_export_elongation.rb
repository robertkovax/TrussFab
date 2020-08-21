NO_HINGE = 0
A_HINGE = 1
B_HINGE = 2
A_B_HINGE = 3

# Exports elongation to SCAD file
class ScadExportElongation
  attr_accessor :hub_id, :other_hub_id, :direction,
                :l1, :l2, :l3, :hinge_connection, :bottle_size, :is_spring

  def initialize(hub_id, other_hub_id, hinge_connection, l1, l2, l3, direction, bottle_size, is_spring = false)
    @hub_id = hub_id
    @other_hub_id = other_hub_id
    @hinge_connection = hinge_connection
    @l1 = l1
    @l2 = l2
    @l3 = l3
    @direction = direction
    @bottle_size = bottle_size
    @is_spring = is_spring
  end

  def total_length
    @l1 + @l2 + @l3
  end
end
