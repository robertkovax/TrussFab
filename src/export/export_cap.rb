class ExportCap
  attr_accessor :length

  def initialize(length)
    @length = length
  end

  def write_to_file(path)
    filename = "#{path}/Cap_#{self.hash}.scad"
    file = File.new(filename, 'w')
    export_string = [
      "// adjust filepath to LibSTLExport if neccessary",
      "use <#{ProjectHelper.library_directory}/openscad/Hinge/cap.scad>",
    "draw_hinge_cap(cap_height=#{@length});"].join("\n") + "\n"

    file.write(export_string)
    file.close
    export_string
  end
end
