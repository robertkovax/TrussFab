# ruby callbacks for right click menus
class ComponentProperties
  def initialize
    add_menu_handler
  end

  def add_menu_handler
    UI.add_context_menu_handler do |context_menu|
      selection = Sketchup.active_model.selection

      next if selection.empty? || !selection.single_object?

      entity = selection.first
      type = entity.get_attribute('attributes', :type)
      id = entity.get_attribute('attributes', :id)

      case type
      when 'ActuatorLink'
        actuator = Graph.instance.edges[id].thingy
        @actuator = actuator
        add_animation_pane(context_menu,
                           '../context-menus/piston.erb',
                           'TrussFab Piston Properties')
      when 'SpringLink'
        spring = Graph.instance.edges[id].thingy
        @spring = spring
        add_spring_menu(context_menu,
                        '../context-menus/spring.erb',
                        'TrussFab Spring Properties')
      when 'GenericLink'
        generic_link = Graph.instance.edges[id].thingy
        @generic_link = generic_link
        add_generic_link_menu(context_menu,
                              '../context-menus/generic_link.erb',
                              'TrussFab Generic Link Properties')
      when 'PidController'
        @pid_controller = Graph.instance.edges[id].thingy
        add_pid_controller_menu(context_menu,
                                '../context-menus/pid_controller.erb',
                                'TrussFab PID-Controller Properties')

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
                     '../context-menus/pod.erb',
                     'TrussFab Pod Properties')
      end
    end
  end

  def add_animation_pane(context_menu, erb_file, title)
    context_menu.add_item(title) do
      show_actuator_dialog(erb_file, title, Configuration::UI_WIDTH, 400)
    end
  end

  def add_spring_menu(context_menu, erb_file, title)
    context_menu.add_item(title) do
      show_spring_dialog(erb_file, title, Configuration::UI_WIDTH, 400)
    end
  end

  def add_generic_link_menu(context_menu, erb_file, title)
    context_menu.add_item(title) do
      show_generic_link_dialog(erb_file, title, Configuration::UI_WIDTH, 400)
    end
  end

  def add_pid_controller_menu(context_menu, erb_file, title)
    context_menu.add_item(title) do
      show_pid_controller_dialog(erb_file, title, Configuration::UI_WIDTH, 600)
    end
  end

  def add_pod_menu(context_menu, erb_file, title)
    context_menu.add_item(title) do
      show_pod_dialog(erb_file, title, Configuration::UI_WIDTH, 400)
    end
  end

  def show_dialog(file,
                  name,
                  width = Configuration::UI_WIDTH,
                  height = Configuration::UI_HEIGHT)
    properties = {
      dialog_title: name,
      scrollable: false,
      resizable: false,
      left: 10,
      top: 100,
      style: UI::HtmlDialog::STYLE_DIALOG
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

  def show_pid_controller_dialog(file,
                                 name,
                                 width = Configuration::UI_WIDTH,
                                 height = Configuration::UI_HEIGHT)
    dialog = show_dialog(file, name, width, height)
    register_pid_controller_callbacks(@pid_controller, dialog)
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
    dialog.add_action_callback('set_damping') do |_dialog, param|
      actuator.reduction = param.to_f
      actuator.update_link_properties
    end
    dialog.add_action_callback('set_rate') do |_dialog, param|
      actuator.rate = param.to_f
      actuator.update_link_properties
    end
    dialog.add_action_callback('set_power') do |_dialog, param|
      actuator.power = param.to_f
      actuator.update_link_properties
    end
    dialog.add_action_callback('set_min') do |_dialog, param|
      actuator.min = param.to_f
      actuator.update_link_properties
    end
    dialog.add_action_callback('set_max') do |_dialog, param|
      actuator.max = param.to_f
      actuator.update_link_properties
    end
  end

  def register_spring_callbacks(spring, dialog)
    # pistons
    dialog.add_action_callback('set_stroke_length') do |_dialog, param|
      spring.stroke_length = param.to_f
      spring.update_link_properties
    end
    dialog.add_action_callback('set_extended_force') do |_dialog, param|
      spring.extended_force = param.to_f
      spring.update_link_properties
    end
    dialog.add_action_callback('set_threshold') do |_dialog, param|
      spring.threshold = param.to_f
      spring.update_link_properties
    end
    dialog.add_action_callback('set_damping') do |_dialog, param|
      spring.damp = param.to_f
      spring.update_link_properties
    end
  end

  def register_generic_link_callbacks(link, dialog)
    # pistons
    dialog.add_action_callback('set_force') do |_dialog, param|
      link.force = param.to_f
      link.update_link_properties
    end
    dialog.add_action_callback('set_min') do |_dialog, param|
      link.min_distance = param.to_f
      link.update_link_properties
    end
    dialog.add_action_callback('set_max') do |_dialog, param|
      link.max_distance = param.to_f
      link.update_link_properties
    end
  end

  def register_pid_controller_callbacks(link, dialog)
    # pistons
    dialog.add_action_callback('set_target') do |_dialog, param|
      link.target_length = param.to_f
      link.update_link_properties
    end
    dialog.add_action_callback('set_p') do |_dialog, param|
      link.k_P = param.to_f
      link.update_link_properties
    end
    dialog.add_action_callback('set_i') do |_dialog, param|
      link.k_I = param.to_f
      link.update_link_properties
    end
    dialog.add_action_callback('set_d') do |_dialog, param|
      link.k_D = param.to_f
      link.update_link_properties
    end
    dialog.add_action_callback('set_min') do |_dialog, param|
      link.min_distance = param.to_f
      link.update_link_properties
    end
    dialog.add_action_callback('set_max') do |_dialog, param|
      link.max_distance = param.to_f
      link.update_link_properties
    end
    dialog.add_action_callback('set_static_force') do |_dialog, param|
      link.static_force = param.to_f
      link.update_link_properties
    end
    dialog.add_action_callback('set_logging') do |_dialog, param|
      link.logging = param
    end
    dialog.add_action_callback('set_error_cap') do |_dialog, param|
      link.integral_error_cap = param.to_f
      link.update_link_properties
    end
  end

  def register_pod_callbacks(pod, dialog)
    dialog.add_action_callback('set_fixed') do |_dialog, param|
      pod.is_fixed = param
    end
  end
end
