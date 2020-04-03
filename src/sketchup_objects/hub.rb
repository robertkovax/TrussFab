require 'src/sketchup_objects/physics_sketchup_object.rb'
require 'src/models/model_storage.rb'
require 'src/simulation/simulation.rb'

# Hub
class Hub < PhysicsSketchupObject
  attr_accessor :position, :body, :mass, :arrow, :user_transformation
  attr_reader :force, :is_user_attached, :user_force

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
    @weight_indicator = nil
    @sensor_symbol = nil
    @is_sensor = false
    @incidents = incidents
    @is_user_attached = false
    @user_indicator = nil
    # force the user applies on that hub in newton
    @user_force = 0
    @user_transformation = Geom::Transformation.new
    update_id_label
    persist_entity
  end

  def add_pod(direction, id: nil, is_fixed: true)
    pod = Pod.new(@position, direction, id: id, is_fixed: is_fixed)
    add(pod)
    pod
  end

  def update_force_arrow
    Sketchup.active_model.start_operation('Hub: Add Force Arrow', true)
    point = Geom::Point3d.new(@position)
    alignment_vec = Geom::Vector3d.new(0, 0, 1)
    unless @arrow.nil?
      @arrow.erase!
      @arrow = nil
    end
    return if @force.length == 0
    model = ModelStorage.instance.models['force_arrow']
    transform = Geom::Transformation.new(point + alignment_vec)
    @arrow = Sketchup.active_model
               .active_entities
               .add_instance(model.definition, transform)
    @arrow.transform!(
      Geom::Transformation.scaling(point + alignment_vec, Math::log(@force.length, 2) / 10) *
        Geometry.rotation_transformation(Geom::Vector3d.new(0, 0, -1), @force, point)
    )
    Sketchup.active_model.commit_operation
  end

  def update_weight_indicator
    unless @weight_indicator.nil?
      @weight_indicator.erase!
      @weight_indicator = nil
    end
    return if @mass == 0
    Sketchup.active_model.start_operation('Hub: Update Weight Indicator', true)
    point = Geom::Point3d.new(@position)
    point.z += 1
    model = ModelStorage.instance.models['weight_indicator']
    transform = Geom::Transformation.new(point)
    @weight_indicator = Sketchup.active_model
                          .active_entities
                          .add_instance(model.definition, transform)
    @weight_indicator.transform!(
      Geom::Transformation.scaling(point, Math::log(@mass, 2) / 5))
    Sketchup.active_model.commit_operation
  end

  # TODO: Extract shared behavior with weight indicator
  def update_user_indicator
    unless @user_indicator.nil?
      @user_indicator.erase!
      @user_indicator = nil
    end
    return unless @is_user_attached

    Sketchup.active_model.start_operation('Hub: Update User Indicator', true)
    point = Geom::Point3d.new(@position)
    point.z += 1
    translation = Geom::Transformation.translation(point)
    @user_indicator = Sketchup.active_model.active_entities.add_instance(@user_indicator_definition, translation * @user_transformation)
    Sketchup.active_model.commit_operation
  end

  def user_indicator_name
    @user_indicator_name
  end

  def move_addon(object, position, offset = Geom::Vector3d.new(0, 0, 0))
    return if object.nil?
    old_pos = object.transformation.origin
    movement_vec = Geom::Transformation.translation(old_pos.vector_to(position +
                                                                        offset))
    object.move!(movement_vec * object.transformation)
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
    @children.select { |child| child.is_a?(Pod) }
  end

  def pods?
    !pods.empty?
  end

  def has_addons?
    !@arrow.nil? || !@weight_indicator.nil? || !@sensor_symbol.nil?
  end

  def delete_addons
    @arrow.erase! unless @arrow.nil?
    @arrow = nil
    @sensor_symbol.erase! unless @sensor_symbol.nil?
    @sensor_symbol = nil
    @weight_indicator.erase! unless @weight_indicator.nil?
    @weight_indicator = nil
    remove_user
  end

  def delete
    delete_addons
    @id_label.erase!
    super
  end

  def update_position(position)
    @position = position
    @entity.move!(Geom::Transformation.new(position) * @model.scaling)
    @id_label.point = position
    move_addons(position)
  end

  def add_sensor_symbol
    point = Geom::Point3d.new(@position)
    model = ModelStorage.instance.models['sensor']
    transform = Geom::Transformation.new(point)
    Sketchup.active_model.start_operation('Hub: Add Sensor Symbol', true)
    @sensor_symbol = Sketchup.active_model
                       .active_entities
                       .add_instance(model.definition, transform)
    @sensor_symbol.transform!(Geom::Transformation.scaling(point, 0.2))
    Sketchup.active_model.commit_operation
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

  def sensor?
    @is_sensor
  end

  def attach_user(force, name:)
    @is_user_attached = true
    @user_force = force
    @user_indicator_definition = ModelStorage.instance.attachable_users[name]
    @user_indicator_name = name
    update_user_indicator
  end

  def remove_user
    @is_user_attached = false
    @user_force = 0
    @user_rotation = 0
    update_user_indicator
  end

  def rotate_user(angle)
    @user_transformation *= Geom::Transformation.rotation(
                              Geom::Point3d.new,
                              Geom::Vector3d.new(0, 0, 1),
                              angle
                            )
    update_user_indicator
  end

  #
  # Physics methods
  #
  def add_weight(weight)
    @mass += weight
    update_weight_indicator
  end

  def weight=(weight)
    @mass = weight
    update_weight_indicator
  end

  def add_force(force)
    self.force += force
  end

  def force=(force)
    @force = force
    update_force_arrow
  end

  def apply_force
    return if @body.nil?
    @body.apply_force(@force)
  end

  def create_body(world)
    num_physics_links = @incidents.count { |x| x.link.is_a?(PhysicsLink) }
    weight = Configuration::HUB_MASS * @incidents.count +
             Configuration::PISTON_MASS * num_physics_links
    # spheres will have it rolling
    @body = Simulation.create_body(world, @entity, :box)
    @body.collidable = true
    @body.mass = @mass.zero? ? weight : @mass + weight
    @body.static_friction = Configuration::BODY_STATIC_FRICITON
    @body.kinetic_friction = Configuration::BODY_KINETIC_FRICITON
    @body.elasticity = Configuration::BODY_ELASTICITY
    @body.softness = Configuration::BODY_SOFTNESS
    @body.static = pods.any?(&:is_fixed)
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
    entity = Sketchup.active_model.entities.add_instance(@model.definition,
                                                         transformation)
    entity.layer = Configuration::HUB_VIEW
    entity.material = @material
    entity
  end

  def update_id_label
    label_position = @position
    if @id_label.nil?
      @id_label = Sketchup.active_model.entities.add_text("    #{@id} ",
                                                          label_position)
      @id_label.layer = Sketchup.active_model.layers[Configuration::HUB_ID_VIEW]
    else
      @id_label.point = label_position
    end
  end
end
