class AnimationDataSample
  attr_reader :time_stamp, :position_data

  def initialize(time_stamp, position_data)
    @time_stamp = time_stamp
    # hash map mapping from each hub to its position at the point in time which time_stamp defines
    @position_data = position_data
  end

  # Matches raw coordinates to hubs in the current graph. Matching will be made based on ids provided in header.
  def self.from_raw_data(data, indices_map, offset_vector = Geom::Vector3d.new())
    time_stamp = data[0]
    position_data = Hash.new(0)

    indices_map.each do | node_id, indices |
      node = Graph.instance.nodes.find do | node |
        node[0] == node_id.to_i
      end

      position = Geom::Point3d.new(data[indices[0]].to_f().mm * 1000,
                                   data[indices[1]].to_f().mm * 1000,
                                   data[indices[2]].to_f().mm * 1000)
      position.offset!(offset_vector.reverse)

      position_data[node_id] = position



    end

    return AnimationDataSample.new(time_stamp, position_data)
  end

  def self.indices_map_from_header(header)
    strings_for_hub_ids = header.group_by do | value |
      if (match = value.match(/node_(\d+)/))
        match.captures[0]
      end
    end

    # remove header and unnecessary lines
    strings_for_hub_ids.delete_if {| value | value.nil?}

    indices_for_hub_ids = Hash.new(0)
    strings_for_hub_ids.each do | key, value |
      # sort array to provide implicit order of x,y,z coordinates
      value.sort_by do | header_string |
        if (match = header_string.match(/,(\d+)/))
          match.captures[0]
        else
          ''
        end
      end

      # map header names to index
      indices_for_hub_ids[key] = value.map { | string | header.index(string) }
    end
    indices_for_hub_ids
  end

  def inspect
    "AnimationDataSample – timestamp: #{@time_stamp} positions for node ids: #{@position_data.inspect}"
  end
end
