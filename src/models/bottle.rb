# Bottle
class Bottle
  attr_reader :definition, :name, :short_name, :length, :weight, :model

  def initialize(name, short_name, weight, definition, model)
    @definition = definition
    @definition.name = name
    @name = name
    @short_name = short_name
    @weight = weight
    @length = @definition.bounds.depth
    @model = model
  end

  def valid?
    @definition.valid?
  end
end
