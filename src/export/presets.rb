module PRESETS
  DEFAULT_HOLE_SIZE = 3.2 # where the screw goes through

  ACTUATOR_CONNECTOR_HOLE_SIZE_SMALL = (6.5 / 2).mm
  ACTUATOR_CONNECTOR_HOLE_SIZE_BIG = (10.5 / 2).mm

  # the angle for the triangle in the gap
  DEFAULT_GAP_ANGLE_SIMPLE = 45
  DEFAULT_GAP_ANGLE_DOUBLE = 70

  # currently removed, but works with appropiate values
  DEFAULT_CUT_OUT_HEX_HEIGHT = 0.0.mm
  DEFAULT_CUT_OUT_HEX_D = 0.0.mm

  # defines what the minimum l1 distance is for hinges
  # values are in mm and are converted to Length class later
  MINIMUM_L1 = 35.mm
  MINIMUM_ACTUATOR_L1 = 40.mm

  # the default l2
  L2 = 40.mm # gap sized derived from this value

  L3_MIN = 10.mm

  SIMPLE_HINGE_OPENSCAD = {
    l2: L2,
    depth: 24.mm, # depth of a hinge part
    width: 100.mm, # not really important because parts that are too much gets cut away anyway
    round_size: 12.mm, # the round part of a hinge part
    gap_angle_a: DEFAULT_GAP_ANGLE_SIMPLE,
    gap_angle_b: DEFAULT_GAP_ANGLE_SIMPLE,
    hole_size_a: DEFAULT_HOLE_SIZE,
    hole_size_b: DEFAULT_HOLE_SIZE,
    gap_epsilon: 0.8.mm, # margin of the gap (due to printing issues)
    connector_end_round: (30.0 / 2).mm,
    connector_end_heigth: 3.7.mm,
    connector_end_extra_round: (19.90 / 2).mm, # to better connect the bottles
    connector_end_extra_height: 7.mm,
    cut_out_hex_height_a: DEFAULT_CUT_OUT_HEX_HEIGHT,
    cut_out_hex_height_b: DEFAULT_CUT_OUT_HEX_HEIGHT,
    cut_out_hex_d_a: DEFAULT_CUT_OUT_HEX_D,
    cut_out_hex_d_b: DEFAULT_CUT_OUT_HEX_D
  }.freeze

  DOUBLE_HINGE_OPENSCAD = SIMPLE_HINGE_OPENSCAD.dup
  DOUBLE_HINGE_OPENSCAD[:alpha] = 40 # add a default
  DOUBLE_HINGE_OPENSCAD[:gap_angle_a] = DEFAULT_GAP_ANGLE_DOUBLE # overwrite
  DOUBLE_HINGE_OPENSCAD[:gap_angle_b] = DEFAULT_GAP_ANGLE_DOUBLE # overwrite

  # caps are currently not used
  CAP_RUBY = SIMPLE_HINGE_OPENSCAD.select do |key, _|
    key.to_s.start_with?('connector_end', 'cut_out', 'round_size')
  end
  CAP_RUBY['hole_size'] = DEFAULT_HOLE_SIZE

  SUBHUB_OPENSCAD = SIMPLE_HINGE_OPENSCAD.select do |key, _|
    key.to_s.start_with?('connector_end', 'gap_epsilon', 'round_size')
  end
  SUBHUB_OPENSCAD['gap_extra_round_size'] = 3.mm
  SUBHUB_OPENSCAD['hole_size'] = DEFAULT_HOLE_SIZE
  SUBHUB_OPENSCAD['l2'] = L2
end

# returns the preset as paramets to use in a openscad function call
def format_hash_for_openscad_params(hash)
  hash = hash.sort_by { |k, _| k.to_s }
  lines = hash.map do |key, value|
    new_value = value.is_a?(Length) ? value.to_mm.round(10) : value
    "  #{key}=#{new_value}"
  end
  lines.join(",\n")
end
