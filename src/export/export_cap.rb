class ExportCap
  attr_accessor :length

  def initialize(length)
    @length = length
  end

  def write_to_file(path)
    filename = "#{path}/Cap_#{self.hash}.scad"
    file = File.new(filename, 'w')
    export_string = 'Cap length: ' + @length.to_s + "\n"

    file.write(export_string)
    file.close
    export_string
  end
end
