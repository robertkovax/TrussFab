require 'src/thingies/physics_thingy.rb'
require 'src/models/model_storage.rb'
require 'src/simulation/simulation.rb'

class Hub < PhysicsThingy
  attr_accessor :position, :body, :mass, :arrow

  def initialize(position, id: nil, material: 'hub_material')
    super(id, material: material)
    @model = ModelStorage.instance.models['ball_hub']
    @color = color unless color.nil?
    @position = position
    @entity = create_entity
    @id_label = nil
    @mass = 0
    @arrow = nil
    @sensor_symbol = nil
    @is_sensor = false
    update_id_label
    persist_entity
  end

  def add_pod(node, direction, id: nil)
    pod = Pod.new(node, @position, direction, id: id)
    add(pod)
    pod
  end

  def add_force_arrow
    point = Geom::Point3d.new(@position)
    point.z += 1
    if @arrow.nil?
      model = ModelStorage.instance.models['force_arrow']
      transform = Geom::Transformation.new(point)
      @arrow = Sketchup.active_model.active_entities.add_instance(model.definition, transform)
    else
      @arrow.transform!(Geom::Transformation.scaling(point, 1.5))
    end
  end

  def move_addons(position)
    move_force_arrow(position)
    move_sensor_symbol(position)
  end

  def move_force_arrow(position)
    return if @arrow.nil?
    old_pos = @arrow.transformation.origin
    movement_vec = old_pos.vector_to(position + Geom::Vector3d.new(0, 0, 1))
    @arrow.transform!(movement_vec)
  end

  def move_sensor_symbol(position)
    return if @sensor_symbol.nil?
    old_pos = @sensor_symbol.transformation.origin
    movement_vec = old_pos.vector_to(position)
    @sensor_symbol.transform!(movement_vec)
  end

  def reset_addon_positions
    reset_force_arrow_position
    reset_sensor_symbol_position
  end

  def reset_force_arrow_position
    return if @arrow.nil?
    move_force_arrow(@position)
  end

  def reset_sensor_symbol_position
    return if @sensor_symbol.nil?
    move_sensor_symbol(@position)
  end

  def pods
    @sub_thingies.select { |sub_thingy| sub_thingy.is_a?(Pod) }
  end

  def pods?
    !pods.empty?
  end

  def delete
    @id_label.erase!
    @arrow.erase! unless @arrow.nil?
    @sensor_symbol.erase! unless @sensor_symbol.nil?
    super
  end

  def update_position(position)
    @position = position
    @entity.move!(Geom::Transformation.new(position))
    @id_label.point = position
    move_addons(position)
  end

  def add_sensor_symbol
    point = Geom::Point3d.new(@position)
    model = ModelStorage.instance.models['sensor']
    transform = Geom::Transformation.new(point)
    @sensor_symbol = Sketchup.active_model.active_entities.add_instance(model.definition, transform)
    @sensor_symbol.transform!(Geom::Transformation.scaling(point, 0.2))
  end

  def toggle_sensor_state
    if @is_sensor
      @is_sensor = false
      @sensor_symbol.erase!
      @sensor_symbol = nil
    else
      @is_sensor = true
      add_sensor_symbol
    end
  end

  def is_sensor?
    @is_sensor
  end

  #
  # Physics methods
  #

  def add_mass(mass)
    @mass += mass
  end

  def add_force
    return if @body.nil?
    @body.apply_force(0, 0, -@mass)
  end

  def create_body(world)
    @body = Simulation.create_body(world, @entity, :box) # spheres will have it rolling
    @body.collidable = true
    @body.mass = Configuration::HUB_MASS
    @body.static_friction = Configuration::BODY_STATIC_FRICITON
    @body.kinetic_friction = Configuration::BODY_KINETIC_FRICITON
    @body.elasticity = Configuration::BODY_ELASTICITY
    @body.softness = Configuration::BODY_SOFTNESS
    @body.static = pods?
    @body
  end

  def joint_position
    @position
  end

  def reset_physics
    super
  end

  private

  def create_entity
    return @entity if @entity
    position = Geom::Transformation.translation(@position)
    transformation = position * @model.scaling
    entity = Sketchup.active_model.entities.add_instance(@model.definition, transformation)
    entity.layer = Configuration::HUB_VIEW
    entity.material = @material
    entity
  end

  def update_id_label
    label_position = @position
    if @id_label.nil?
      @id_label = Sketchup.active_model.entities.add_text("    #{@id} ", label_position)
      @id_label.layer = Sketchup.active_model.layers[Configuration::HUB_ID_VIEW]
    else
      @id_label.point = label_position
    end
  end
end
