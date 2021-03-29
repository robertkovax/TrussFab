class Widget
  attr_reader :position, :current_state
  LABEL_HEIGHT = 2.0


  def initialize(position, valid_states, image_path, state: nil)
    @position = position

    # Reverse valid_states so that the easiest is the upper most
    @states = valid_states.reverse
    @image_path = image_path

    state = valid_states.length - 1 unless state
    @current_state = state

    @instances = []
    @group = Sketchup.active_model.active_entities.add_group
    create_geometry
    create_image
    update
  end

  def update

  end

  def create_image
    # TODO: Make sure that we can use @group here
    #
    image_width = 7
    image = @group.entities.add_image(
      @image_path,
      Geom::Point3d.new,
      image_width,
    )
    rotation = Geometry.rotation_transformation(Geom::Vector3d.new(0, 0, 1), Geom::Vector3d.new(0, -1, 0), Geom::Point3d.new)
    image.transform! rotation

    translation = Geom::Transformation.translation(Geom::Vector3d.new(-(image.bounds.width/2),  0, 16.cm))
    image.transform! translation
    image.parent.behavior.always_face_camera = true
  end

  def create_geometry
    @group = Sketchup.active_model.entities.add_group if @group.deleted?
    @group.name = "Widget"
    group_entities = @group.entities

    # create a defintion for each label
    @states.each_with_index do |state, index|
      parent = Sketchup.active_model.definitions.add "Parent #{state}"
      parent.behavior.always_face_camera = true
      label_definition = Sketchup.active_model.definitions.add "Widget Label #{state}"
      # label_definition.behavior.always_face_camera = true
      entities = label_definition.entities
      bold = index == @current_state
      success = entities.add_3d_text(state, TextAlignLeft, "Arial", bold, false, LABEL_HEIGHT, 0.0, 0, true, 0.1)

      rotation = Geometry.rotation_transformation(Geom::Vector3d.new(0, 0, 1), Geom::Vector3d.new(0, -1, 0), Geom::Point3d.new(0, 0, 0))
      internal_translation = Geom::Transformation.translation(Geom::Vector3d.new(-label_definition.bounds.width/2,  0, index * LABEL_HEIGHT * 1.2))
      translation = Geom::Transformation.translation(@position)
      # translation = Geom::Transformation.translation(Geom::Vector3d.new(-label_definition.bounds.width / 2,  0, 0))
      transform = internal_translation * rotation

      instance = parent.entities.add_instance(label_definition, transform)
      instance.material = index == @current_state ? Sketchup::Color.new(20, 20, 20) : Sketchup::Color.new(150, 150, 150)

      @group.transformation = translation
      group_entities.add_instance(parent, Geom::Transformation.new)
      @instances << instance

    end
  end

  def cycle!
    @current_state = (@current_state - 1) % @states.length
    update_states
  end

  def remove
    Sketchup.active_model.active_entities.erase_entities(@group.entities.to_a) if @group && !@group.deleted?
  end

  def update_states
    remove
    create_geometry
    create_image
  end
end
