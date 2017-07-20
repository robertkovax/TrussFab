module ActuatorGroupHelper

  def self.next_group(old_group)
    # returns next group
  end

  def self.previus_group(old_group)
    # returns previous group
  end

  def self.new_group
    # creates a new group with a new random color
    # and standart schedule
  end

  def schedule_for(group)
  end

  private_class_method

  def self.next_color
    
  end
  def self.set_style
    styles = Sketchup.active_model.styles
    styles.add_style(plugin_directory + '/Bottle Editor Style1.style', false)
    styles.selected_style = styles['Bottle Editor Style1']
  end

  def self.create_layers
    layers = Sketchup.active_model.layers

    model_layer = layers.add(Configuration::LINE_VIEW)
    model_layer.visible = false

    layers.add(Configuration::COMPONENT_VIEW)
    layers.add(Configuration::HUB_VIEW)
    layers.add(Configuration::DRAW_TOOLTIPS_VIEW)
    layers.add(Configuration::TRIANGLE_SURFACES_VIEW)

    connector_mode_layer = layers.add(Configuration::CONNECTOR_MODE_VIEW)
    connector_mode_layer.visible = false

    hub_id_layer = layers.add(Configuration::HUB_ID_VIEW)
    hub_id_layer.visible = false

    # layers.add Configuration::FORCE_VIEW
    # force_label_layer = layers.add Configuration::FORCE_LABEL_VIEW
    # force_label_layer.visible = false
  end

  def self.setup_surface_materials
    material = Sketchup.active_model.materials.add('surface_color')
    material.color = [1, 1, 1]
    material.alpha = 0.03

    material = Sketchup.active_model.materials.add('surface_highlighted_color')
    material.color = [0.5, 0.5, 0.5]
    material.alpha = 1

    material = Sketchup.active_model.materials.add('highlight_color')
    material.color = [1, 1, 1]
    material.alpha = 0.8

    material = Sketchup.active_model.materials.add('standard_color')
    material.color = [0.5, 0.2, 0.3]
    material.alpha = 1

    material = Sketchup.active_model.materials.add('piston_a')
    material.color = [0.1, 0.7, 1]
    material.alpha = 1

    material = Sketchup.active_model.materials.add('piston_b')
    material.color = [0.3, 1, 0.1]
    material.alpha = 1

    material = Sketchup.active_model.materials.add('piston_c')
    material.color = [0.7, 0.1, 0.3]
    material.alpha = 1

    material = Sketchup.active_model.materials.add('piston_d')
    material.color = [1, 0.3, 0.7]
    material.alpha = 1

    material = Sketchup.active_model.materials.add('elongation_color')
    material.color = Configuration::ELONGATION_COLOR
    material.alpha = 1
  end
end
