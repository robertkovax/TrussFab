class Bottle
  attr_reader :definition, :name, :length, :weight

  def initialize name, weight, definition
    @definition = definition
    @definition.name = name
    @name = name
    @weight = weight
    @length = @definition.bounds.depth
  end
end