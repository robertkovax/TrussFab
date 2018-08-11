# ruby integration for the force charts
class ForceChart
  def initialize(sensors)
    @root_dir = File.join(__dir__, '..')
    @sensors = sensors
  end

  def open_dialog
    @dialog = UI::HtmlDialog.new(Configuration::HTML_DIALOG)
    file_content = File.read(File.join(File.dirname(__FILE__),
                                       '../force-chart/sensor_overview.erb'))
    template = ERB.new(file_content)
    @dialog.set_html(template.result(binding))
    # if this is commented in, the window size will be reset on every start
    # @dialog.set_size(300, Configuration::UI_HEIGHT)
    @dialog.show
  end

  def close
    @dialog.close
  end

  def visible?
    @dialog.visible?
  end

  def add_chart_data(sensor_id, label, data, datatype, sensortype)
    @dialog.execute_script("addChartData(#{sensor_id},"\
                           " '#{label}',"\
                           " #{data},"\
                           " '#{datatype}',"\
                           " '#{sensortype}');")
  end

  def shift_data
    @dialog.execute_script('shiftData();')
  end

  def reset_chart(sensor_id)
    @dialog.execute_script("resetChart(#{sensor_id});")
  end
end
