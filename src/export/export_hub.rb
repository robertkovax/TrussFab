require 'src/export/presets.rb'


class ExportHub
  def initialize(id)
    @id = id
    @elongations = []
  end

  def add_elongation(elongation)
    @elongations.push(elongation)
  end
end

class ExportSubHub < ExportHub
  def initialize(id)
    super(id)
    @params = {
      'normal_vectors' => [[-0.9948266171932849, -0.00015485714145741815, 0.1015872912476312], [-0.3984857593670732, -0.28854789426039135, 0.8706027867515364],[-0.4641256842132446, -0.883604515803502, 0.06189029734333352]],
      'gap_types' => ["b", "a", "none"],
      'connector_types' => ["none", "bottle", "bottle"],
      'l3' => [0, 10, 10],
      'l1' => 30.mm
    }
  end

  def write_to_file(path)
    p 'subhub:'
    @elongations.each do |elongation|
      'elongation ' + elongation.hinge_connection.to_s
    end

    # TODO: rename get_defaults_for_openscad
    params = get_defaults_for_openscad(@params)
    default_params = get_defaults_for_openscad(PRESETS::SUBHUB_OPENSCAD)
    filename = "#{path}/SubHub_#{@id}.scad"
    file = File.new(filename, 'w')

    export_string = ["// adjust filepath to LibSTLExport if necessary",
      "use <#{ProjectHelper.library_directory}/openscad/Hinge/subhub.scad>",
      "draw_subhub(",
    ].join("\n") + "\n" + params + ",\n" + default_params + ");\n"

    file.write(export_string)
    file.close
    export_string
  end
end

class ExportMainHub < ExportHub
  def initialize(id)
    super(id)
    @pods = []
  end

  def add_pod(pod)
    @pods.push(pod)
  end

  def write_to_file(path)
    filename = "#{path}/Hub_#{@id}.scad"
    file = File.new(filename, 'w')

    mode = 'Tube'

    vector_array = []
    addon_array = []
    type_array = []

    @elongations.each do |elongation|
      if elongation.hinge_connection == NO_HINGE
        type_array << '"HOLE"'
      else
        type_array << '"PLUG"'
      end

      vector_array << "[#{elongation.direction.to_a.join(', ')}]"
      addon_array << "[#{elongation.length}, \"#{elongation.other_hub_id}\"]"
    end

    @pods.each do |pod|
      addon_array << '[(45 - 0 - 10), "STAND",0,24,10,60,0]'
      type_array << '"STAND"'
      vector_array << "[" + pod.direction.normalize.to_a.join(', ').to_s + "]"
    end

    export_string =
        "// adjust filepath to LibSTLExport if neccessary\n" \
        "include <#{ProjectHelper.library_directory}/openscad/LibSTLExport.scad>\n" \
        "\n" \
        "hubID = \"#{@id}\";\n" \
        "mode = \"#{mode}\";\n" \
        "safetyFlag = false;\n" \
        "connectorDataDistance = 0;\n" \
        "tubeThinning = 1.0;\n" \
        "useFixedCenterSize = false;\n" \
        "hubCenterSize = 0;\n" \
        "printVectorInteger = 8;\n" \
        "dataFileVectorArray = [\n" \
        "#{vector_array.join(",\n")}\n" \
        "];\n" \
        "dataFileAddonParameterArray = [\n" \
        "#{addon_array.join(",\n")}\n" \
        "];\n" \
        "connectorTypeArray = [\n" \
        "#{type_array.join(",\n")}\n" \
        "];\n" \
        "drawHub(dataFileVectorArray, dataFileAddonParameterArray, connectorTypeArray);\n"

    file.write(export_string)
    file.close
    export_string
  end
end
