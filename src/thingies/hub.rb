require 'src/thingies/physics_thingy.rb'
require 'src/models/model_storage.rb'
require 'src/simulation/simulation.rb'

class Hub < PhysicsThingy
  attr_accessor :position, :body, :mass, :arrow

  def initialize(position, id: nil, incidents: nil, material: 'hub_material')
    super(id, material: material)
    @model = ModelStorage.instance.models['ball_hub']
    @color = color unless color.nil?
    @position = position
    @entity = create_entity
    @id_label = nil
    @mass = 0
    @force = Geom::Vector3d.new(0, 0, 0)
    @arrow = nil
    @sensor_symbol = nil
    @is_sensor = false
    @incidents = incidents
    update_id_label
    persist_entity
  end

  def add_pod(direction, id: nil, is_fixed: true)
    pod = Pod.new(@position, direction, id: id, is_fixed: is_fixed)
    add(pod)
    pod
  end

  def add_force_arrow
    Sketchup.active_model.start_operation('Hub: Add Force Arrow', true)
    point = Geom::Point3d.new(@position)
    point.z += 1
    if @arrow.nil?
      model = ModelStorage.instance.models['force_arrow']
      transform = Geom::Transformation.new(point)
      @arrow = Sketchup.active_model.active_entities.add_instance(model.definition, transform)
    else
      @arrow.transform!(Geom::Transformation.scaling(point, 1.5))
    end
    Sketchup.active_model.commit_operation
  end

  def add_weight_indicator
    Sketchup.active_model.start_operation('Hub: Add Weight Indicator', true)
    point = Geom::Point3d.new(@position)
    point.z += 1
    if @weight_indicator.nil?
      model = ModelStorage.instance.models['weight_indicator']
      transform = Geom::Transformation.new(point)
      @weight_indicator = Sketchup.active_model.active_entities.add_instance(model.definition, transform)
    else
      @weight_indicator.transform!(Geom::Transformation.scaling(point, 1.5))
    end
    Sketchup.active_model.commit_operation
  end

  def move_addon(object, position, offset = Geom::Vector3d.new(0, 0, 0))
    return if object.nil?
    Sketchup.active_model.start_operation('Hub: Move Addon', true)
    old_pos = object.transformation.origin
    movement_vec = old_pos.vector_to(position + offset)
    object.transform!(movement_vec)
    Sketchup.active_model.commit_operation
  end

  def move_addons(position)
    move_force_arrow(position)
    move_weight_indicator(position)
    move_sensor_symbol(position)
    pods.each { |pod| pod.update_position(position) }
  end

  def move_force_arrow(position)
    move_addon(@arrow, position, Geom::Vector3d.new(0, 0, 1))
  end

  def move_weight_indicator(position)
    move_addon(@weight_indicator, position, Geom::Vector3d.new(0, 0, 1))
  end

  def move_sensor_symbol(position)
    move_addon(@sensor_symbol, position)
  end

  def reset_addon_positions
    reset_force_arrow_position
    reset_weight_indicator_position
    reset_sensor_symbol_position
    pods.each { |pod| pod.update_position(@position) }
  end

  def reset_force_arrow_position
    return if @arrow.nil?
    move_force_arrow(@position)
  end

  def reset_weight_indicator_position
    return if @weight_indicator.nil?
    move_weight_indicator(@position)
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
    @weight_indicator.erase! unless @weight_indicator.nil?
    super
  end

  def update_position(position)
    Sketchup.active_model.start_operation('Hub: Update Position')
    @position = position
    @entity.move!(Geom::Transformation.new(position))
    @id_label.point = position
    move_addons(position)
    Sketchup.active_model.commit_operation
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
  def add_weight(weight)
    @mass = @mass + weight
  end

  def add_force(force)
    @force = @force + force
  end

  def apply_force
    return if @body.nil?
    @body.apply_force(@force)
  end

  def create_body(world)
    num_physics_links = @incidents.count { |x| x.thingy.is_a?(PhysicsLink)}
    weight = Configuration::HUB_MASS * @incidents.count + Configuration::PISTON_MASS * num_physics_links
    @body = Simulation.create_body(world, @entity, :box) # spheres will have it rolling
    @body.collidable = true
    @body.mass = @mass == 0 ? weight : @mass
    @body.static_friction = Configuration::BODY_STATIC_FRICITON
    @body.kinetic_friction = Configuration::BODY_KINETIC_FRICITON
    @body.elasticity = Configuration::BODY_ELASTICITY
    @body.softness = Configuration::BODY_SOFTNESS
    @body.static = pods.any? { |pod| pod.is_fixed }
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
