module PRESETS
  default_hole_size = 3.2.mm # where the screw goes through
  default_gap_angle = 45.mm # the angle for the triangle in the gap, because of a hack, we give it as mm, it actually is as degrees

  # to remove the Hexagon, set both values to 0
  #default_cut_out_hex_height = 5.mm
  #default_cut_out_hex_d = 10.6.mm
  default_cut_out_hex_height = 0.mm
  default_cut_out_hex_d = 0.mm

  SIMPLE_HINGE_OPENSCAD = {
    'depth' => 24.mm, # depth of a hinge part
    'width' => 100.mm, # not really important because parts that are too much gets cut away anyway
    'round_size' => 12.mm, # the round part of a hinge part
    'gap_angle_a' => default_gap_angle,
    'gap_angle_b' => default_gap_angle,
    'hole_size_a' => default_hole_size,
    'hole_size_b' => default_hole_size,
    'extra_width_for_hinging' => 6.mm, # there needs to be an extra offset so the hinge part can swing fully
    'gap_height' => 10.mm, # gap of a hinge part
    'gap_epsilon' => 0.8.mm, # margin of the gap (due to printing issues)
    'connector_end_round' => (30.0 / 2).mm,
    'connector_end_heigth' => 3.7.mm,
    'connector_end_extra_round' => (19.9 / 2).mm, # to better connect the bottles
    'connector_end_extra_height' => 7.mm,
    'cut_out_hex_height_a' => default_cut_out_hex_height,
    'cut_out_hex_height_b' => default_cut_out_hex_height,
    'cut_out_hex_d_a' => default_cut_out_hex_d,
    'cut_out_hex_d_b' => default_cut_out_hex_d
  }.freeze

  ACTUATOR_HINGE_OPENSCAD = SIMPLE_HINGE_OPENSCAD.dup

  ACTUATOR_HINGE_OPENSCAD['extra_width_for_hinging'] = 1.mm
  ACTUATOR_HINGE_OPENSCAD['gap_angle'] = 70.mm

  ACTUATOR_HINGE_OPENSCAD_ANGLE = 40
  ACTUATOR_HINGE_OPENSCAD_HOLE_SIZE = (7.0 / 2).mm

  CAP_RUBY = SIMPLE_HINGE_OPENSCAD.select do |key, _|
    key.start_with?('connector_end', 'cut_out', 'round_size')
  end

  CAP_RUBY['hole_size'] = default_hole_size

  SIMPLE_HINGE_RUBY = SIMPLE_HINGE_OPENSCAD.dup

  SIMPLE_HINGE_RUBY['l3_min'] = 10.mm
  SIMPLE_HINGE_RUBY['l2'] =
    4 * SIMPLE_HINGE_RUBY['gap_height'] +
    1.5 * SIMPLE_HINGE_RUBY['gap_epsilon']

  # values are in mm and are converted to Length class later
  MINIMUM_L1 = 35
  MINIMUM_ACTUATOR_L1 = 40
end

# returns the preset as paramets to use in a openscad function call
def get_defaults_for_openscad(preset)
  lines = preset.map do |key, value|
    "#{key}=#{value.to_mm}"
  end
  lines.join(",\n")
end

def save_to_scad(hash, path)
  lines = hash.map do |key, value|
    "#{key} = #{value.to_mm};"
  end

  File.open(path, 'w') do |file|
    file.write(lines.join("\n"))
  end
end
