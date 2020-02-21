# Ruby integration for spring insights dialog
class SpringPane
  INSIGHTS_HTML_FILE = '../spring-pane/index.erb'.freeze

  def initialize(refresh_callback, toggle_animation_callback)
    @refresh_callback = refresh_callback
    @toggle_animation_callback = toggle_animation_callback

    @spring_links = Graph.instance.edges.values.
        select { |edge| edge.link_type == 'spring' }.
        map(&:link)

    @dialog = nil
    open_dialog
  end

  def set_period(value)
    @dialog.execute_script("set_period(#{value})")
  end

  def open_dialog
    return if @insights_dialog && @insights_dialog.visible?

    props = {
        resizable: true,
        preferences_key: 'com.trussfab.spring_insights',
        width: 200,
        height: 50 + @spring_links.length * 200,
        left: 5,
        top: 5,
        # max_height: @height
        style: UI::HtmlDialog::STYLE_DIALOG
    }

    @dialog = UI::HtmlDialog.new(props)
    file_path = File.join(File.dirname(__FILE__), INSIGHTS_HTML_FILE)
    content = File.read(file_path)
    t = ERB.new(content)
    @dialog.set_html(t.result(binding))
    @dialog.set_position(500, 500)
    @dialog.show
    register_insights_callbacks
  end

  private

  def register_insights_callbacks
    @dialog.add_action_callback('spring_insights_change') do |_, spring_id, value|
      @refresh_callback.call(spring_id, value)
    end

    @dialog.add_action_callback('spring_insights_toggle_play') do
      @toggle_animation_callback.call
    end
  end

end
