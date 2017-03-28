class ProjectHelper
  def self.plugin_directory
    File.expand_path('../..', File.dirname(__FILE__))
  end

  def self.source_directory
    plugin_directory + '/source'
  end

  def self.asset_directory
    plugin_directory + '/assets'
  end

  def self.utility_directory
    source_directory + '/utility'
  end

  def self.tool_directory
    source_directory + '/tools'
  end

  def self.database_directory
    source_directory + '/database'
  end

  def self.model_directory
    source_directory + '/models'
  end

  def self.component_directory
    asset_directory + '/sketchup_components'
  end

  def self.require_multiple(path_wildcard)
    Dir[self.plugin_directory + '/../' + path_wildcard].each {|file| require file}
  end

  def self.setup_sketchup
    Sketchup.active_model.options["UnitsOptions"]["LengthUnit"] = 2 # print and display lengths in mm
    Sketchup.active_model.options["UnitsOptions"]["LengthFormat"] = 0 # print and display lengths as decimal number
    set_style
    create_layers
    setup_surface_materials
  end

  private
  def self.create_layers
    layers = Sketchup.active_model.layers

    model_layer = layers.add Configuration::LINE_VIEW
    model_layer.visible = false

    layers.add Configuration::COMPONENT_VIEW
    layers.add Configuration::HUB_VIEW
    layers.add Configuration::DRAW_TOOLTIPS_VIEW
    layers.add Configuration::TRIANGLE_SURFACES_VIEW

    connector_mode_layer = layers.add Configuration::CONNECTOR_MODE_VIEW
    connector_mode_layer.visible = false

    hub_id_layer = layers.add Configuration::HUB_ID_VIEW
    hub_id_layer.visible = false

    # layers.add Configuration::FORCE_VIEW
    # force_label_layer = layers.add Configuration::FORCE_LABEL_VIEW
    # force_label_layer.visible = false
  end

  def self.set_style
    styles = Sketchup.active_model.styles
    styles.add_style(plugin_directory + '/Bottle Editor Style1.style', false)
    styles.selected_style = styles["Bottle Editor Style1"]
  end

  def self.setup_surface_materials
    material = Sketchup.active_model.materials.add('surface_color')
    material.color = [1,1,1]
    material.alpha = 0.03

    material = Sketchup.active_model.materials.add('surface_highlighted_color')
    material.color = [1,1,1]
    material.alpha = 0.5
  end
end