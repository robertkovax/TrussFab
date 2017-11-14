require 'src/thingies/physics_thingy.rb'
require 'src/models/model_storage.rb'
require 'src/simulation/simulation.rb'

class Hub < PhysicsThingy
  attr_accessor :position, :body, :mass

  def initialize(position, id: nil, material: 'hub_material')
    super(id, material: material)
    @model = ModelStorage.instance.models['ball_hub']
    @color = color unless color.nil?
    @position = position
    @entity = create_entity
    @id_label = nil
    @mass = 0
    update_id_label
  end

  def add_pod(node, direction, id: nil)
    pod = Pod.new(node, @position, direction, id: id)
    add(pod)
    pod
  end

  def pods
    @sub_thingies.select { |sub_thingy| sub_thingy.is_a?(Pod) }
  end

  def pods?
    !pods.empty?
  end

  def delete
    @id_label.erase!
    super
  end

  def update_position(position)
    @position = position
    @entity.move!(Geom::Transformation.new(position))
    @id_label.point = position
    @sub_thingies.each { |sub_thingy| sub_thingy.update_position(position) }
  end

  #
  # Physics methods
  #

  def add_mass(mass)
    @mass += mass
  end

  def update_force
    @body.set_force(0, 0, -@mass)
  end

  def create_body(world)
    @body = Simulation.create_body(world, @entity, collision_type: :sphere)
    @body.collidable = true
    @body.mass = @mass <= 0 ? Simulation::HUB_MASS : @mass
    @body.auto_sleep_enabled = false
    pods.each do |pod|
      pod_body = pod.create_body(world)
      joint = joint_to(world, MSPhysics::Fixed, pod_body, pod.direction, solver_model: 1)
    end
    update_force
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
