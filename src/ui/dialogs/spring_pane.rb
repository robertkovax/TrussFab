# Ruby integration for spring insights dialog
class SpringPane
  INSIGHTS_HTML_FILE = '../spring-insights/index.html'.freeze

  def initialize(visualization, constant, animation, refresh_callback, toggle_animation_callback)
    @refresh_callback = refresh_callback
    @toggle_animation_callback = toggle_animation_callback

    @dialog = nil
    open_dialog
  end

  def set_period(value)
    @dialog.execute_script("set_period(#{value})")
  end

  def open_dialog
    return if @insights_dialog
    props = {
        # resizable: false,
        preferences_key: 'com.trussfab.spring_insights',
        width: 200,
        height: 250,
        left: 5,
        top: 5,
        min_width: 400,
        min_height: 120,
        # max_height: @height
        :style => UI::HtmlDialog::STYLE_UTILITY
    }

    @dialog = UI::HtmlDialog.new(props)
    file = File.join(File.dirname(__FILE__), INSIGHTS_HTML_FILE)
    @dialog.set_file(file)
    @dialog.set_position(500, 500)
    @dialog.show
    register_insights_callbacks
  end

  private

  def register_insights_callbacks
    @dialog.add_action_callback('spring_insights_change') do |_, value|
      @refresh_callback.call(value)
    end

    @dialog.add_action_callback('spring_insights_toggle_play') do |_, value|
      @toggle_animation_callback.call
    end
  end

end
