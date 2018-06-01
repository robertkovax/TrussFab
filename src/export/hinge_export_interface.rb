# HingeExportInterface
class HingeExportInterface
  attr_reader :edge1, :edge2, :is_double_hinge

  def initialize(edge1, edge2, is_double_hinge)
    raise 'Edges have to be different.' if edge1 == edge2
    @edge1 = edge1
    @edge2 = edge2
    @is_double_hinge = is_double_hinge
  end

  def inspect
    "#{@edge1.inspect} #{@edge2.inspect} #{@is_double_hinge}"
  end

  def hash
    self.class.hash ^ @edge1.hash ^ @edge2.hash
  end

  def eql?(other)
    hash == other.hash
  end

  def connected_with?(other)
    common_edges = edges & other.edges
    common_edges.any?
  end

  def num_connected_hinges(hinges)
    hinges.select { |other| !eql?(other) && connected_with?(other) }.size
  end

  def edges
    [@edge1, @edge2]
  end

  def swap_edges
    @edge1, @edge2 = @edge2, @edge1
  end

  def angle
    val = @edge1.direction.angle_between(@edge2.direction)
    val = 180 / Math::PI * val
    val = 180 - val if val > 90

    raise 'Angle between edges not between 0° and 90°.' if val < 0 || val > 90

    val
  end

  def l1
    @is_double_hinge ? PRESETS::MINIMUM_ACTUATOR_L1 : PRESETS::MINIMUM_L1
  end
end
