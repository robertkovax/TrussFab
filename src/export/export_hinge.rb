# TODO
# * two hinges on one elongation
# * subhub
#

require 'src/export/presets.rb'

DISTANCES_PARAMS = ['l1', 'l2', 'a_l3', 'b_l3']

class ExportHinge
  def initialize(hub_id, a_other_hub_id, b_other_hub_id, type, params)
    distances = params.select { |k, _| DISTANCES_PARAMS.include? k.to_s }
    distances.each { |k, v| raise "#{k} must not be negative, was: #{v}" if v < 0 }

    if type == :simple
      @params = PRESETS::SIMPLE_HINGE_OPENSCAD.clone
    elsif type == :double
      @params = PRESETS::DOUBLE_HINGE_OPENSCAD.clone
    else
      raise 'specify hinge type'
    end

    @params = @params.merge(params) # overwrites defaults

    @hub_id = hub_id
    @a_other_hub_id = a_other_hub_id
    @b_other_hub_id = b_other_hub_id
  end

  def write_to_file(path)
    filename = "#{path}/Hinge_#{@hub_id}.#{@a_other_hub_id}_#{@hub_id}.#{@b_other_hub_id}.scad"
    file = File.new(filename, 'w')
    params = format_hash_for_openscad_params(@params)
    export_string = [
      "// adjust filepath to LibSTLExport if necessary",
      "use <#{ProjectHelper.library_directory}/openscad/Kinematics/hinge.scad>",
      "draw_hinge(",
      "  a_label=\"#{@a_other_hub_id}\",",
      "  b_label=\"#{@b_other_hub_id}\",",
      "  id_label=\"#{'N' + @hub_id.to_s}\","
    ].join("\n") + "\n" + params + "\n);\n"
    file.write(export_string)
    file.close
    export_string
  end
end
