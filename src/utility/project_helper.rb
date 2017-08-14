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
    Sketchup.active_model.options['UnitsOptions']['LengthUnit'] = 2 # print and display lengths in mm
    Sketchup.active_model.options['UnitsOptions']['LengthFormat'] = 0 # print and display lengths as decimal number
    set_style
    create_layers
    setup_surface_materials
  end

  private_class_method

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

    material = Sketchup.active_model.materials.add('standard_material')
    material.color = Configuration::STANDARD_COLOR
    material.alpha = 1

    material = Sketchup.active_model.materials.add('surface_material')
    material.color = Configuration::SURFACE_COLOR
    material.alpha = 0.03

    material = Sketchup.active_model.materials.add('surface_highlight_material')
    material.color = Configuration::SURFACE_HIGHLIGHT_COLOR
    material.alpha = 1

    material = Sketchup.active_model.materials.add('highlight_material')
    material.color = Configuration::HIGHLIGHT_COLOR
    material.alpha = 1

    material = Sketchup.active_model.materials.add('hub_material')
    material.color = Configuration::HUB_COLOR
    material.alpha = 1

    material = Sketchup.active_model.materials.add('elongation_material')
    material.color = Configuration::ELONGATION_COLOR
    material.alpha = 1

    material = Sketchup.active_model.materials.add('wooden_cover')
    material.texture = asset_directory + '/textures/plywood.jpg'
    material.alpha = 1
  end
end
