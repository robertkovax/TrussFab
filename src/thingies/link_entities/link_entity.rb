require 'src/thingies/thingy.rb'

class LinkEntity < Thingy
  attr_reader :id, :entity
  attr_accessor :color
  def initialize(id = nil, color: 'piston_a')
    super(id)
    @color = color
    @entity = create_entity
  end

  def create_entity
    raise NotImplementedError
  end

  def highlight(highlight_color = @highlight_color)
    change_color(highlight_color)
  end

  def un_highlight
    change_color(@color)
  end
end
