class ComponentProperties
  def initialize
    add_menu_handler
  end

  def add_menu_handler
    UI.add_context_menu_handler do |context_menu|
      sel = Sketchup.active_model.selection
      if sel.empty? || !sel.single_object?
        next
      end
      entity = sel.first
      type = entity.get_attribute('attributes', :type)
      id = entity.get_attribute('attributes', :id)

      case type
      when 'ActuatorLink'
        actuator = Graph.instance.edges[id].thingy
        add_piston_menu(context_menu, actuator, 'erb/piston_dialog.erb')
      end

      # type_name = entity.get_attribute(Configuration::DICTIONARY_NAME, :type)
      # id = entity.get_attribute(Configuration::DICTIONARY_NAME, :id)

    end
  end

  def add_piston_menu(context_menu, actuator, erb_file)
    context_menu.add_item("TrussFab Piston Properties") {
      @actuator = actuator
      @title = "TrussFab Piston Properties"
      show_dialog(erb_file, @title, Configuration::UI_WIDTH, 400)
    }
  end

  def show_dialog(file,
                  name,
                  width = Configuration::UI_WIDTH,
                  height = Configuration::UI_HEIGHT)

    #close old window
    unless @dialog.nil?
      if @dialog.visible?
        @dialog.close
      end
    end

    properties = {
      :dialog_title => name,
      :scrollable => false,
      :resizable => false,
      :left => 10,
      :top => 100,
      :style => UI::HtmlDialog::STYLE_DIALOG
    }.freeze

    @dialog = UI::HtmlDialog.new(properties)
    @dialog.set_size(width, height)

    @location = File.dirname(__FILE__)
    @dialog.set_html(render(file))

    @dialog.show

    register_callbacks
  end

  def render(path)
    content = File.read(File.join(@location, path))
    t = ERB.new(content)
    t.result(binding)
  end

  def register_callbacks
    # pistons
    @dialog.add_action_callback('set_dampening') do |dialog, param|
      value = param.to_f
      Sketchup.active_model.start_operation("Set Piston Dampening", true)
      @actuator.dampening = value
      @actuator.update_piston
      Sketchup.active_model.commit_operation
    end
    @dialog.add_action_callback('set_rate') do |dialog, param|
      value = param.to_f
      Sketchup.active_model.start_operation("Set Piston Rate", true)
      @actuator.rate = value
      @actuator.update_piston
      Sketchup.active_model.commit_operation
    end
    @dialog.add_action_callback('set_power') do |dialog, param|
      value = param.to_f
      Sketchup.active_model.start_operation("Set Piston Power", true)
      @actuator.power = value
      @actuator.update_piston
      Sketchup.active_model.commit_operation
    end
    @dialog.add_action_callback('set_min') do |dialog, param|
      value = param.to_f
      Sketchup.active_model.start_operation("Set Piston Minimum", true)
      @actuator.min = value
      @actuator.update_piston
      Sketchup.active_model.commit_operation
    end
    @dialog.add_action_callback('set_max') do |dialog, param|
      value = param.to_f
      Sketchup.active_model.start_operation("Set Piston Maximum", true)
      @actuator.max = value
      @actuator.update_piston
      Sketchup.active_model.commit_operation
    end
  end
end
