# Bottle
class Pipe
  attr_reader :definition, :name, :short_name, :length, :weight, :model

  def initialize(name, short_name, weight, definition, model, length)
    @definition = definition
    @definition.name = name
    @name = name
    @short_name = short_name
    @weight = weight
    @length = length
    @model = model
  end

  def valid?
    @definition.valid?
  end
end
