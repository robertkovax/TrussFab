class ForceChart
  def initialize
    @root_dir = File.join(__dir__, '..')
  end

  def open_dialog
    @dialog = UI::HtmlDialog.new(Configuration::HTML_DIALOG)
    file_content = File.read(File.join(File.dirname(__FILE__), '../ui/erb/chart.erb'))
    template = ERB.new(file_content)
    @dialog.set_html(template.result(binding))
    @dialog.set_size(300, Configuration::UI_HEIGHT)
    @dialog.show
    @dialog.add_action_callback('onClick') do |_context, button_id|
      addData(0, 5)
    end
  end

  def close
    @dialog.close
  end

  def addData(label, data)
    @dialog.execute_script("addData('#{label}', '#{data}')")
  end
end
