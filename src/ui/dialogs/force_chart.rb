class ForceChart

  def initialize(sensors)
    @root_dir = File.join(__dir__, '..')
    @sensors = sensors
  end

  def open_dialog
    @dialog = UI::HtmlDialog.new(Configuration::HTML_DIALOG)
    file_content = File.read(File.join(File.dirname(__FILE__), '../force-chart/sensor_overview.erb'))
    template = ERB.new(file_content)
    @dialog.set_html(template.result(binding))
    @dialog.set_size(300, Configuration::UI_HEIGHT)
    @dialog.show
  end

  def close
    @dialog.close
  end

  def visible?
    @dialog.visible?
  end

  def add_chart_data(sensor_id, label, data)
    @dialog.execute_script("addChartData(#{sensor_id}, '#{label}', #{data});")
  end

  def shiftData
    @dialog.execute_script("shiftData();")
  end

  def reset_chart(sensor_id)
    @dialog.execute_script("resetChart(#{sensor_id});")
  end

  def update_speed(sensor_id, speed)
    @dialog.execute_script("updateSpeed('#{sensor_id}', '#{speed}');")
  end

  def update_acceleration(sensor_id, acceleration)
    @dialog.execute_script("updateAcceleration('#{sensor_id}', '#{acceleration}');")
  end
end
