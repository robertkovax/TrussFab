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
        @actuator = actuator
        add_actuator_menu(context_menu,
                          'erb/piston_dialog.erb',
                          'TrussFab Piston Properties')
      when 'SpringLink'
        spring = Graph.instance.edges[id].thingy
        @spring = spring
        add_spring_menu(context_menu,
                        'erb/spring_dialog.erb',
                        'TrussFab Spring Properties')
      when 'GenericLink'
        generic_link = Graph.instance.edges[id].thingy
        @generic_link = generic_link
        add_generic_link_menu(context_menu,
                              'erb/generic_link_dialog.erb',
                              'TrussFab Generic Link Properties')
      when 'Pod'
        @pod = nil
        Graph.instance.nodes.values.each do |node|
          if node.pod?(id)
            @pod = node.pod(id)
            break
          end
        end

        raise 'Pod not found' if @pod.nil?

        add_pod_menu(context_menu,
                     'erb/pod_dialog.erb',
                     'TrussFab Pod Properties')
      end

    end
  end

  def add_actuator_menu(context_menu, erb_file, title)
    context_menu.add_item(title) {
      show_actuator_dialog(erb_file, title, Configuration::UI_WIDTH, 400)
    }
  end

  def add_spring_menu(context_menu, erb_file, title)
    context_menu.add_item(title) {
      show_spring_dialog(erb_file, title, Configuration::UI_WIDTH, 400)
    }
  end

  def add_generic_link_menu(context_menu, erb_file, title)
    context_menu.add_item(title) {
      show_generic_link_dialog(erb_file, title, Configuration::UI_WIDTH, 400)
    }
  end

  def add_pod_menu(context_menu, erb_file, title)
    context_menu.add_item(title) {
      show_pod_dialog(erb_file, title, Configuration::UI_WIDTH, 400)
    }
  end

  def show_dialog(file,
                  name,
                  width = Configuration::UI_WIDTH,
                  height = Configuration::UI_HEIGHT)
    properties = {
      :dialog_title => name,
      :scrollable => false,
      :resizable => false,
      :left => 10,
      :top => 100,
      :style => UI::HtmlDialog::STYLE_DIALOG
    }.freeze

    dialog = UI::HtmlDialog.new(properties)
    dialog.set_size(width, height)

    @location = File.dirname(__FILE__)
    dialog.set_html(render(file))

    dialog.show
    dialog
  end

  def show_actuator_dialog(file,
                           name,
                           width = Configuration::UI_WIDTH,
                           height = Configuration::UI_HEIGHT)
    dialog = show_dialog(file, name, width, height)
    register_actuator_callbacks(@actuator, dialog)
  end

  def show_spring_dialog(file,
                         name,
                         width = Configuration::UI_WIDTH,
                         height = Configuration::UI_HEIGHT)
    dialog = show_dialog(file, name, width, height)
    register_spring_callbacks(@spring, dialog)
  end

  def show_generic_link_dialog(file,
                               name,
                               width = Configuration::UI_WIDTH,
                               height = Configuration::UI_HEIGHT)
    dialog = show_dialog(file, name, width, height)
    register_generic_link_callbacks(@generic_link, dialog)
  end

  def show_pod_dialog(file,
                      name,
                      width = Configuration::UI_WIDTH,
                      height = Configuration::UI_HEIGHT)
    dialog = show_dialog(file, name, width, height)
    register_pod_callbacks(@pod, dialog)
  end

  def render(path)
    content = File.read(File.join(@location, path))
    t = ERB.new(content)
    t.result(binding)
  end

  def register_actuator_callbacks(actuator, dialog)
    # pistons
    dialog.add_action_callback('set_damping') do |dialog, param|
      actuator.reduction = param.to_f
      actuator.update_link_properties
    end
    dialog.add_action_callback('set_rate') do |dialog, param|
      actuator.rate = param.to_f
      actuator.update_link_properties
    end
    dialog.add_action_callback('set_power') do |dialog, param|
      actuator.power = param.to_f
      actuator.update_link_properties
    end
    dialog.add_action_callback('set_min') do |dialog, param|
      actuator.min = param.to_f
      actuator.update_link_properties
    end
    dialog.add_action_callback('set_max') do |dialog, param|
      actuator.max = param.to_f
      actuator.update_link_properties
    end
  end

  def register_spring_callbacks(spring, dialog)
    # pistons
    dialog.add_action_callback('set_stroke_length') do |dialog, param|
      spring.stroke_length = param.to_f
      spring.update_link_properties
    end
    dialog.add_action_callback('set_extended_force') do |dialog, param|
      spring.extended_force = param.to_f
      spring.update_link_properties
    end
    dialog.add_action_callback('set_threshold') do |dialog, param|
      spring.threshold = param.to_f
      spring.update_link_properties
    end
    dialog.add_action_callback('set_damping') do |dialog, param|
      spring.damp = param.to_f
      spring.update_link_properties
    end
  end

  def register_generic_link_callbacks(link, dialog)
    # pistons
    dialog.add_action_callback('set_force') do |dialog, param|
      link.force = param.to_f
      link.update_link_properties
    end
    dialog.add_action_callback('set_min') do |dialog, param|
      link.min_distance = param.to_f
      link.update_link_properties
    end
    dialog.add_action_callback('set_max') do |dialog, param|
      link.max_distance = param.to_f
      link.update_link_properties
    end
  end

  def register_pod_callbacks(pod, dialog)
    dialog.add_action_callback('set_fixed') do |dialog, param|
      pod.is_fixed = param
    end
  end
end
