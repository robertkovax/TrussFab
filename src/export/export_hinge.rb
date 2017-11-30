# TODO
# * two hinges on one elongation
# * subhub

class ExportHinge
  def initialize(a_l1, a_l2, a_l3, b_l1, b_l2, b_l3, connection_angle, a_gap, b_gap, a_is_l3_solid, b_is_l3_solid)
    @a_l1 = a_l1
    @a_l2 = a_l2
    @a_l3 = a_l3
    @b_l1 = b_l1
    @b_l2 = b_l2
    @b_l3 = b_l3
    @connection_angle = connection_angle
    @a_gap = a_gap
    @b_gap = b_gap
    @a_is_l3_solid = a_is_l3_solid
    @b_is_l3_solid = b_is_l3_solid
  end

  def write_to_file(path)
    filename = "#{path}/Hinge_#{self.hash}.scad"
    file = File.new(filename, 'w')
    export_string = [
      "// adjust filepath to LibSTLExport if neccessary",
      "use <#{ProjectHelper.library_directory}/openscad/Hinge/simple_hinge.scad>",
    "draw_hinge(alpha=#{@connection_angle}, a_l1=#{@a_l1}, a_l2=#{@a_l2}, a_l3=#{@a_l3}, a_gap=#{@a_gap}, b_l1=#{@b_l1}, b_l2=#{@b_l2}, b_l3=#{@b_l3}, b_gap=#{@b_gap});"].join("\n") + "\n"

    file.write(export_string)
    file.close
    export_string
  end
end
