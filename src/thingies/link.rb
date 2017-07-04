require 'src/thingies/link_entities/connector.rb'
require 'src/thingies/link_entities/elongation.rb'
require 'src/thingies/link_entities/line.rb'
require 'src/thingies/link_entities/bottle_link.rb'
require 'src/simulation/simulation_helper.rb'
require 'src/thingies/physics_thingy.rb'

class Link < PhysicsThingy
  attr_accessor :line, :first_joint, :second_joint
  attr_reader :body

  def initialize(first_position, second_position, model_name, id: nil)
    super(id)

    @position = first_position
    @second_position = second_position

    @first_joint = nil
    @second_joint = nil

    @model = ModelStorage.instance.models[model_name]
    @line = nil

    create_sub_thingies
  end

  def update_positions(first_position, second_position)
    @position = first_position
    @second_position = second_position
    delete_sub_thingies
    create_sub_thingies
  end

  def length
    @position.distance(@second_position)
  end

  def mid_point
    Geom::Point3d.linear_combination(0.5, @position, 0.5, @second_position)
  end

  def joint_position
    mid_point
  end

  def group
    entities = @sub_thingies.flat_map(&:all_entities)
    Sketchup.active_model.entities.add_group(entities)
  end

  def create_body(world)
    c1, e1, bottles, _, e2, c2 = @sub_thingies
    @body = MSPhysics::Body.new(world, bottles.entity, :convex_hull)
    ext_1_body = SimulationHelper.body_for(world, c1, e1)
    ext_2_body = SimulationHelper.body_for(world, c2, e2)

    @body.mass = SimulationHelper::LINK_MASS
    @body.collidable = true
    [ext_1_body, ext_2_body].each do |body|
      body.mass = SimulationHelper::ELONGATION_MASS
      body.collidable = false
      body.gravity_enabled = true
    end

    joint_to(world, MSPhysics::Fixed, ext_1_body, mid_point.vector_to(@position))
    joint_to(world, MSPhysics::Fixed, ext_2_body, mid_point.vector_to(@second_position))

    @body
  end

  def create_joints(world)
    [@first_joint, @second_joint].each do |joint|
      joint.create(world, @body)
    end
  end

  def create_sub_thingies

    first_elong_length = second_elong_length = Configuration::MINIMUM_ELONGATION

    model_length = length - first_elong_length - second_elong_length
    shortest_model = @model.longest_model_shorter_than(model_length)

    first_elong_length = second_elong_length = (length - shortest_model.length) / 2


    direction = @position.vector_to(@second_position)
    first_elongation = Elongation.new(@position,
                                      direction,
                                      first_elong_length)
    link_position = @position.offset(first_elongation.direction)

    @line = Line.new(@position, @second_position)

    add(Connector.new(@position, direction, first_elong_length),
        first_elongation,
        BottleLink.new(link_position, direction, shortest_model.definition),
        @line,
        Elongation.new(@second_position,
                       direction.reverse,
                       second_elong_length),
        Connector.new(@second_position,
                      direction.reverse,
                      second_elong_length))
  end
end
