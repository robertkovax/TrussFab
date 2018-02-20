# TODO
# * two hinges on one elongation
# * subhub
#

require 'src/export/presets.rb'

class ExportHinge
  def initialize(hub_id, a_other_hub_id, b_other_hub_id,
    a_l1, a_l2, a_l3, b_l1, b_l2, b_l3, connection_angle,
    a_gap, b_gap, a_with_connector, b_with_connector, presets)
    
    if [a_l1, a_l2, a_l3, b_l1, b_l2, b_l3].any? { |x| x < 0 }
      raise "l1, l2, and l3 must not be negative: #{[a_l1, a_l2, a_l3, b_l1, b_l2, b_l3]}"
    end

    @hub_id = hub_id
    @a_other_hub_id = a_other_hub_id
    @b_other_hub_id = b_other_hub_id
    @a_l1 = a_l1
    @a_l2 = a_l2
    @a_l3 = a_l3
    @b_l1 = b_l1
    @b_l2 = b_l2
    @b_l3 = b_l3
    @connection_angle = connection_angle
    @a_gap = a_gap
    @b_gap = b_gap
    @a_with_connector = a_with_connector
    @b_with_connector = b_with_connector
    @presets = presets.clone
  end

  def write_to_file(path)
    filename = "#{path}/Hinge_#{@hub_id}.#{@a_other_hub_id}_#{@hub_id}.#{@b_other_hub_id}.scad"
    file = File.new(filename, 'w')
    params = get_defaults_for_openscad(@presets)
    export_string = [
      "// adjust filepath to LibSTLExport if necessary",
      "use <#{ProjectHelper.library_directory}/openscad/Hinge/simple_hinge.scad>",
      "draw_hinge(",
      "alpha=#{@connection_angle},",
      "a_l1=#{@a_l1},",
      "a_l2=#{@a_l2},",
      "a_l3=#{@a_l3},",
      "a_gap=#{@a_gap},",
      "b_l1=#{@b_l1},",
      "b_l2=#{@b_l2},",
      "b_l3=#{@b_l3},",
      "b_gap=#{@b_gap},",
      "a_with_connector=#{@a_with_connector},",
      "b_with_connector=#{@b_with_connector},",
      "a_label=\"#{@a_other_hub_id}\",",
      "b_label=\"#{@b_other_hub_id}\",",
      "id_label=\"#{'N' + @hub_id.to_s}\","
    ].join("\n") + "\n" + params + ");\n"
    file.write(export_string)
    file.close
    export_string
  end
end
