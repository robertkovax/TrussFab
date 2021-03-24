class Widget
  LABEL_HEIGHT = 3


  def initialize(position, valid_states)
    @position = position
    @states = valid_states
    @current_state = 0

    @instances = []
    @group = Sketchup.active_model.active_entities.add_group
    create_geometry
    update
  end

  def update

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
      success = entities.add_3d_text(state, TextAlignCenter, "Arial", index == @current_state, false, LABEL_HEIGHT, 0.0, 0, true, 0.1)

      rotation = Geometry.rotation_transformation(Geom::Vector3d.new(0, 0, 1), Geom::Vector3d.new(0, -1, 0), Geom::Point3d.new(0, 0, 0))
      internal_translation = Geom::Transformation.translation(Geom::Vector3d.new(0,  0, index * LABEL_HEIGHT * 1.2))
      translation = Geom::Transformation.translation(@position)
      # translation = Geom::Transformation.translation(Geom::Vector3d.new(-label_definition.bounds.width / 2,  0, 0))
      transform = internal_translation * rotation

      instance = parent.entities.add_instance(label_definition, transform)
      instance.material = index == @current_state ? Sketchup::Color.new(100, 100, 100) : Sketchup::Color.new(230, 230, 230)

      @group.transformation = translation
      group_entities.add_instance(parent, Geom::Transformation.new)
      @instances << instance

    end
    # group_entities.add_observer(MySelectionObserver.new)
    Sketchup.active_model.selection.add_observer(MySelectionObserver.new do
      cycle!
    end)
  end

  def cycle!
    @current_state = (@current_state + 1) % @states.length
    update_states
  end

  def update_states
    @instances.each_with_index do |instance, index|
      instance.material = index == @current_state ? Sketchup::Color.new(100, 100, 100) : Sketchup::Color.new(230, 230, 230)
    end
  end
end

class MySelectionObserver < Sketchup::SelectionObserver
  def initialize(&block)
    @onSelection = block
  end

  def onSelectionBulkChange(selection)
    # TODO that's a bit hacky, identifying the group via label but I didn't find another way
    locked = selection.grep(Sketchup::Group).find_all{|g| g.name == "Widget" }
    if locked[0]
      @onSelection.call
      Sketchup.active_model.selection.clear
    end
  end
end
