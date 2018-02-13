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
  end

  def write_to_file(path)
    p 'subhub:'
    @elongations.each do |elongation|
      'elongation ' + elongation.hinge_connection.to_s
    end
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
