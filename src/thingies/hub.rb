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

  def move_force_arrow(position)
    return if @arrow.nil?
    @arrow.move!(Geom::Transformation.new(position))
    @arrow.transform!(Geom::Transformation.new(Geom::Point3d.new(0, 0, 1)))
  end

  def reset_force_arrow_position
    return if @arrow.nil?
    @arrow.move!(Geom::Transformation.new(@position))
    @arrow.transform!(Geom::Transformation.new(Geom::Point3d.new(0, 0, 1)))
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
    super
  end

  def update_position(position)
    @position = position
    @entity.move!(Geom::Transformation.new(position))
    @id_label.point = position
    move_force_arrow(position)
    @sub_thingies.each { |sub_thingy| sub_thingy.update_position(position) }
  end

  #
  # Physics methods
  #

  def add_mass(mass)
    @mass += mass
  end

  def create_body(world)
    @body = Simulation.create_body(world, @entity, collision_type: :sphere)
    @body.collidable = true
    @body.mass = @mass <= 0 ? Simulation::HUB_MASS : @mass
    pods.each do |pod|
      pod_body = pod.create_body(world)
      joint_to(world, MSPhysics::Fixed, pod_body, pod.direction, solver_model: 1)
    end
    @body
  end

  def joint_position
    @position
  end

  def reset_physics
    super
    pods.each do |pod|
      pod.body = nil
    end
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
      @id_label = Sketchup.active_model.entities.add_text("    #{@id} ", label_position)
      @id_label.layer = Sketchup.active_model.layers[Configuration::HUB_ID_VIEW]
    else
      @id_label.point = label_position
    end
  end
end
