# TODO
# * two hinges on one elongation
# * subhub

class ExportHinge
  def initialize(a_l1, a_l2, a_l3, b_l1, b_l2, b_l3, connection_angle, a_gap, b_gap, a_is_l3_solid, b_is_l3_solid)
    @a_l1 = a_l1
    @a_l2 = a_l2
    @a_l3 = a_l3
    @b_l1 = b_l1
    @b_l2 = b_l2
    @b_l3 = b_l3
    @connection_angle = connection_angle
    @a_gap = a_gap
    @b_gap = b_gap
    @a_is_l3_solid = a_is_l3_solid
    @b_is_l3_solid = b_is_l3_solid
  end
end
