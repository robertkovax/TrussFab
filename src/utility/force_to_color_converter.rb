class ColorConverter
  class << self

    def convert_temp_color(t_color, t_1, t_2)
      color = 0
      if 6 * t_color < 1
        color = t_2 + (t_1 - t_2) * 6 * t_color
      elsif 2 * t_color < 1
        color = t_1
      elsif 3 * t_color < 2
        color = t_2 + (t_1 - t_2) * (2/3 - t_color) * 6
      else
        color = t_2
      end

      color
    end

    def hsl_to_rgb(h, s, l)
       r = 0
       g = 0
       b = 0

      # https://www.niwa.nu/2013/05/math-behind-colorspace-conversions-rgb-hsl/
      if s == 0
          r = g = b = l;
      else
          t_1 = 0
          if l < 0.5
            t_1 = l * (1.0 + s)
          else
            t_1 = l + s - l * s
          end

          t_2 = 2 * l - t_1
          h1 = h/360.0

          t_r = h1 + 0.333
          if t_r > 1
            t_r = t_r - 1
          end
          t_g = h1
          t_b = h1 - 0.333
          r = convert_temp_color(t_r, t_1, t_2)
          g = convert_temp_color(t_g, t_1, t_2)
          b = convert_temp_color(t_b, t_1, t_2)

          rgb = [r, g, b]
      end

      rgb
    end

    def get_color_for_force(force)
      value = force.abs / 100.0 # [0N, 100N] => [0, 0.5]
      value = 1 if value > 0.5
      value = 0 if value < 0
      # strong negative force will be blue (stretching), strong positive force
      # will be red (compression)
      # In HSL, a hue value of 200 degrees is a light blue color, 360 degrees is red
      h = force <= 0 ? 200.0 : 360.0
      s = 1
      l = 1 - value

      hsl_to_rgb(h, s, l)
    end
  end
end
