require 'src/thingies/physics_thingy.rb'
require 'src/models/model_storage.rb'
require 'src/simulation/simulation_helper.rb'

class Hub < PhysicsThingy
  attr_accessor :position, :body

  def initialize(position, id: nil, color: nil)
    super(id)
    @model = ModelStorage.instance.models['ball_hub']
    @color = color unless color.nil?
    @entity = create_entity(position)
    @position = position
  end

  def highlight(highlight_color = @highlight_color)
    change_color(highlight_color)
  end

  def un_highlight
    change_color(@color)
  end

  def update_position(position)
    @position = position
    @entity.move!(Geom::Transformation.new(position))
  end

  def create_body(world)
    @body = MSPhysics::Body.new(world, @entity, :sphere)
    @body.collidable = true
    @body.mass = SimulationHelper::HUB_MASS
    @body
  end

  def joint_position
    @position
  end

  private

  def create_entity(position)
    return @entity if @entity
    position = Geom::Transformation.translation(position)
    transformation = position * @model.scaling
    entity = Sketchup.active_model.entities.add_instance(@model.definition,
                                                         transformation)
    entity.layer = Configuration::HUB_VIEW
    entity.material = @color
    entity
  end
end
