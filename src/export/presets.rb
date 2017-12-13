module PRESETS
  SIMPLE_HINGE_OPENSCAD = {
    "depth" => 24, # depth of a hinge part
    "width" => 100, # not really important because parts that are too much gets cut away anyway
    "round_size" => 12, # the round part of a hinge part
    "hole_size" => 3.1, # where the screw goes through
    "gap_angle" => 45, # the angle for the triangle in the gap
    "extra_width_for_hinging" => 6, # there needs to be an extra offset so the hinge part can swing fully
    "gap_height" => 10, # gap of a hinge part
    "gap_epsilon" => 0.8, # margin of the gap (due to printing issues)
    "connector_end_round" => 30/2,
    "connector_end_heigth" => 4,
    "connector_end_extra_round" => 19.5/2,
    "connector_end_extra_height" => 2,
  }

  SIMPLE_HINGE_RUBY = SIMPLE_HINGE_OPENSCAD.clone

  SIMPLE_HINGE_RUBY['l3_min'] = 10
  SIMPLE_HINGE_RUBY['l2'] =
    4 * SIMPLE_HINGE_RUBY['gap_height'] +
    1.5 * SIMPLE_HINGE_RUBY['gap_epsilon']

  # returns the preset as paramets to use in a openscad function call
  def get_parameters_s preset
    lines = preset.map do |key, value|
      "#{key}=#{value}"
    end
    lines.join(',')
  end
end

def save_to_scad(hash, path)
  lines = hash.map do |key, value|
    "#{key} = #{value};"
  end

  File.open(path, 'w') do |file|
    file.write(lines.join("\n"))
  end
end

if $PROGRAM_NAME == __FILE__
  save_to_scad SIMPLE_HINGE_OPENSCAD, 'lib/openscad/Hinge/preset.scad'
end
