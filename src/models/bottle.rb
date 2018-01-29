class Bottle
  attr_reader :definition, :name, :length, :weight, :model

  def initialize(name, weight, definition, model)
    @definition = definition
    @definition.name = name
    @name = name
    @weight = weight
    @length = @definition.bounds.depth
    @model = model
  end

  def valid?
    @definition.valid?
  end

end
