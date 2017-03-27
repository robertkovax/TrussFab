class MouseInput
  attr_reader :position

  def soft_reset
    @position = nil
  end

  def update_positions(view, x, y)
    soft_reset

    input_point = Sketchup::InputPoint.new
    input_point.pick(view, x, y, Sketchup::InputPoint.new)

    @position = input_point.position
  end
end