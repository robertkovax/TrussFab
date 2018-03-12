class ActuatorMenu
  def initialize
    @HTML_FILE = '../html/actuator-menu.html'
  end

  def open_dialog
    width = 500
    height = 200

    left = 240
    top = 740 - height

    props = {
      :resizable => false,
      :width => width,
      :height => height,
      :left => left,
      :top => top,
      :min_width => width,
      :min_height =>height,
      :max_width => width,
      :max_height => height
    }

    @dialog = UI::HtmlDialog.new(props)
    file = File.join(File.dirname(__FILE__), @HTML_FILE)
    @dialog.set_file(file)
    # @dialog.set_siSkeze(Configuration::UI_WIDTH, Configuration::UI_HEIGHT)
    @dialog.set_position(left, top)
    @dialog.show
    @dialog.add_action_callback('documentReady') { register_callbacks }

  end

  def close_dialog
    @dialog.close
  end

  def refresh
    file = File.join(File.dirname(__FILE__), @HTML_FILE)
    @dialog.set_file(file)
  end

  private

  def register_callbacks
  # TODO
  end

end
