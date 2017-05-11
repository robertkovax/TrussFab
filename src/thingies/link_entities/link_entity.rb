require 'src/thingies/thingy.rb'

class LinkEntity < Thingy
  attr_reader :id, :entity

  def initialize(id = nil)
    super(id)
    @entity = create_entity
  end

  def create_entity
    raise NotImplementedError
  end

  def highlight(highlight_color = @highlight_color)
    @last_color = color
    change_color(highlight_color)
  end

  def un_highlight
    return if @last_color.nil?
    change_color(@last_color)
  end
end
