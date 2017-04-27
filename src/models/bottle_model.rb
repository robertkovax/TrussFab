require 'src/models/bottle.rb'

class BottleModel
  attr_reader :name, :models

  def initialize(name, specifications)
    @name = name
    @models = {}
    specifications.each do |specification|
      @models[specification[:NAME]] = create_model(specification)
    end
  end

  def find_model_shorter_than(length)
    long_model = shortest_model
    @models.values.each do |model|
      next if model.length > length
      long_model = model if model.length > long_model.length
    end
    long_model
  end

  def find_model_longer_than(length)
    short_model = longest_model
    @models.values.each do |model|
      next if model.length < length
      short_model = model if model.length < short_model.length
    end
    short_model
  end

  def longest_model
    @models.values.max_by(&:length)
  end

  def shortest_model
    @models.values.min_by(&:length)
  end

  private

  def create_model(specification)
    components = Sketchup.active_model.definitions # Sketchup Component Definitions
    name = specification[:NAME]
    if components[name]
      model = components[name]
    else
      definition = components.load specification[:PATH]
      model = Bottle.new(name, specification[:WEIGHT], definition, self)
    end
    model
  end
end
