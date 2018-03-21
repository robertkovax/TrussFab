class ForceChart
  def initialize
    @root_dir = File.join(__dir__, '..')
  end

  def open_dialog
    @dialog = UI::HtmlDialog.new(Configuration::HTML_DIALOG)
    file_content = File.read(File.join(File.dirname(__FILE__), '../html/force_chart.html'))
    template = ERB.new(file_content)
    @dialog.set_html(template.result(binding))
    @dialog.set_size(300, Configuration::UI_HEIGHT)
    @dialog.show
  end

  def close
    @dialog.close
  end

  def addData(label, data)
    @dialog.execute_script("addData('#{label}', '#{data}');")
  end
  
  def shiftData
    @dialog.execute_script("shiftData();")
  end
end
