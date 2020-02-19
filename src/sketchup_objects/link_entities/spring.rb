require 'src/sketchup_objects/sketchup_object.rb'
require 'src/simulation/simulation.rb'
require 'src/models/parametric_spring_model.rb'

# Spring
class Spring < SketchupObject
  attr_reader :material

  def initialize(parent, definition, id = nil)
    super(id)
    @definition = definition
    @entity = create_entity
    @parent = parent
    persist_entity(type: parent.class.to_s, id: parent.id)
  end

  def create_entity
    return @entity if @entity

    Sketchup.active_model.active_entities.
        add_instance(@definition, Geom::Transformation.new);
  end

  def material=(material)
    @material = material
    change_color(material)
  end

  def change_color(color)
    @entity.material = color
    @entity.material.alpha = 1.0
  end
end
