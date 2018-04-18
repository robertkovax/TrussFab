module ProjectHelper
  def self.plugin_directory
    File.expand_path('../..', File.dirname(__FILE__))
  end

  def self.asset_directory
    plugin_directory + '/assets'
  end

  def self.library_directory
    plugin_directory + '/lib'
  end

  def self.component_directory
    asset_directory + '/sketchup_components'
  end

  def self.require_multiple(path_wildcard)
    files = Dir.glob(plugin_directory + '/' + path_wildcard)
    files.each { |file| require file }
  end

  def self.setup_sketchup
    model = Sketchup.active_model
    model.start_operation('TrussFab Setup', true)
    model.options['UnitsOptions']['LengthUnit'] = 2 # print and display lengths in mm
    model.options['UnitsOptions']['LengthFormat'] = 0 # print and display lengths as decimal number
    setup_style
    setup_layers
    setup_surface_materials
    model.commit_operation
  end

  private_class_method

  def self.setup_style
    styles = Sketchup.active_model.styles
    unless styles['Bottle Editor Style1']
      styles.add_style(plugin_directory + '/Bottle Editor Style1.style', false)
      styles.selected_style = styles['Bottle Editor Style1']
    end
  end

  def self.setup_layers
    layers = Sketchup.active_model.layers

    unless layers[Configuration::LINE_VIEW]
      model_layer = layers.add(Configuration::LINE_VIEW)
      model_layer.visible = false
    end

    unless layers[Configuration::COMPONENT_VIEW]
      layers.add(Configuration::COMPONENT_VIEW)
    end

    unless layers[Configuration::HUB_VIEW]
      layers.add(Configuration::HUB_VIEW)
    end

    unless layers[Configuration::ACTUATOR_VIEW]
      layers.add(Configuration::ACTUATOR_VIEW)
    end

    unless layers[Configuration::DRAW_TOOLTIPS_VIEW]
      layers.add(Configuration::DRAW_TOOLTIPS_VIEW)
    end

    unless layers[Configuration::TRIANGLE_SURFACES_VIEW]
      layers.add(Configuration::TRIANGLE_SURFACES_VIEW)
    end

    unless layers[Configuration::HINGE_VIEW]
      hinge_layer = layers.add(Configuration::HINGE_VIEW)
      hinge_layer.visible = false
    end

    unless layers[Configuration::HUB_ID_VIEW]
      hub_id_layer = layers.add(Configuration::HUB_ID_VIEW)
      hub_id_layer.visible = false
    end

    unless layers[Configuration::FORCE_VIEW]
      layers.add(Configuration::FORCE_VIEW)
    end

    unless layers[Configuration::FORCE_LABEL_VIEW]
      force_label_layer = layers.add(Configuration::FORCE_LABEL_VIEW)
      #force_label_layer.visible = false
    end
  end

  def self.setup_surface_materials
    materials = Sketchup.active_model.materials

    unless materials['standard_material']
      material = materials.add('standard_material')
      material.color = Configuration::STANDARD_COLOR
      material.alpha = 1
    end

    unless materials['bottle_material']
      material = materials.add('bottle_material')
      material.color = Configuration::BOTTLE_COLOR
      material.alpha = 0.65
    end

    unless materials['actuator_material']
      material = materials.add('actuator_material')
      material.color = Configuration::ACTUATOR_COLOR
      material.alpha = 1
    end

    unless materials['spring_material']
      material = materials.add('spring_material')
      material.color = Configuration::SPRING_COLOR
      material.alpha = 1
    end

    unless materials['generic_link_material']
      material = materials.add('generic_link_material')
      material.color = Configuration::GENERIC_LINK_COLOR
      material.alpha = 1
    end

    unless materials['surface_material']
      material = materials.add('surface_material')
      material.color = Configuration::SURFACE_COLOR
      material.alpha = 0.03
    end

    unless materials['surface_highlight_material']
      material = materials.add('surface_highlight_material')
      material.color = Configuration::SURFACE_HIGHLIGHT_COLOR
      material.alpha = 1
    end

    unless materials['highlight_material']
      material = materials.add('highlight_material')
      material.color = Configuration::HIGHLIGHT_COLOR
      material.alpha = 1
    end

    unless materials['hub_material']
      material = materials.add('hub_material')
      material.color = Configuration::HUB_COLOR
      material.alpha = 1
    end

    unless materials['elongation_material']
      material = materials.add('elongation_material')
      material.color = Configuration::ELONGATION_COLOR
      material.alpha = 1
    end

    unless materials['wooden_cover']
      material = materials.add('wooden_cover')
      material.texture = asset_directory + '/textures/plywood.jpg'
      material.alpha = 1
    end
  end
end
