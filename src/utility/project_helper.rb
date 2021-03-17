# used for setting up layers, getting paths

require 'socket'
require 'timeout'

def port_open?(host, port)
  Timeout::timeout(5) do
    begin
      TCPSocket.new(host, port).close
      true
    rescue Errno::ECONNREFUSED, Errno::EHOSTUNREACH
      false
    end
  end
rescue Timeout::Error
  false
end

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

  def self.spring_catalogue_directory
    asset_directory + '/spring_catalogues'
  end

  def self.require_multiple(path_wildcard)
    files = Dir.glob(plugin_directory + '/' + path_wildcard)
    files.each { |file| require file }
  end

  def self.system_simulation_directory
    plugin_directory + '/src/system_simulation'
  end

  def self.setup_sketchup
    setup_simulation_server
    model = Sketchup.active_model
    model.start_operation('TrussFab Setup', true)
    # print and display lengths in mm
    model.options['UnitsOptions']['LengthUnit'] = 2
    # print and display lengths as decimal number
    model.options['UnitsOptions']['LengthFormat'] = 0
    setup_style
    setup_layers
    setup_surface_materials
    model.commit_operation
  end

  private_class_method

  def self.setup_simulation_server
    host = Configuration::SIMULATION_SERVER_HOST
    port = Configuration::SIMULATION_SERVER_PORT
    if Configuration::LAUNCH_SIMULATION_SERVER_WITH_SKETCHUP and not port_open?(host, port)
      if Configuration::SIMULATION_SERVER_HOST == "localhost"
        simulation_start_script = File.join(Dir.pwd, "src", "julia", "start.jl")
        if ENV['OS'] == 'Windows_NT'
          command = "start \"Trusscillator Simulation Server\" \"#{ENV['APPDATA']}\\..\\Local\\Programs\\Julia 1.5.3\\bin\\julia.exe\" #{simulation_start_script} #{port}"
          # for pasting directly in a Windows Terminal use this command (work directory := project root):
          # & "$env:APPDATA\..\Local\Programs\Julia 1.5.3\bin\julia.exe" src/julia/start.jl 8085"
          p command
        else
          # we assume, we are on macOS
          command = "osascript -e \'tell app \"Terminal\"
              do script \"julia #{simulation_start_script} #{port}\"
            end tell\'"
        end
        IO.popen command
      else
        p "The Simulation Server at #{host}:#{port} is not reachable. TrussFab did not try to spin up the server automatically as the host was sth other than localhost"
      end
    end
    # else we assume server is already running
  end

  def self.setup_style
    styles = Sketchup.active_model.styles
    return if styles['Bottle Editor Style1']
    styles.add_style(plugin_directory + '/Bottle Editor Style1.style', false)
    styles.selected_style = styles['Bottle Editor Style1']
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

    unless layers[Configuration::SPRING_INSIGHTS]
      spring_insights_layer = layers.add(Configuration::SPRING_INSIGHTS)
      spring_insights_layer.visible = false
    end

    unless layers[Configuration::MAXIMUM_ACCELERATION_VELOCITY_VIEW]
      maximum_acceleration_layer = layers.add(Configuration::MAXIMUM_ACCELERATION_VELOCITY_VIEW)
      maximum_acceleration_layer.visible = false
    end

    unless layers[Configuration::SPRING_DEBUGGING]
      spring_insights_layer = layers.add(Configuration::SPRING_DEBUGGING)
      spring_insights_layer.visible = true
    end

    unless layers[Configuration::FORCE_VIEW]
      layers.add(Configuration::FORCE_VIEW)
    end

    unless layers[Configuration::FORCE_LABEL_VIEW]
      force_label_layer = layers.add(Configuration::FORCE_LABEL_VIEW)
    end

    unless layers[Configuration::MOTION_TRACE_VIEW]
      layers.add(Configuration::MOTION_TRACE_VIEW)
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
      material.alpha = 1.0
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

    unless materials['pid_material']
      material = materials.add('pid_material')
      material.color = Configuration::PID_COLOR
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

    unless materials['amplitude_handle_material']
      material = materials.add('amplitude_handle_material')
      material.color = Sketchup::Color.new(1.0, 0, 0)
      material.alpha = 1
    end
  end
end
