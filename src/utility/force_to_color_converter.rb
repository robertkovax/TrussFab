class ColorConverter
  class << self
    def hue_2_rgb(c, x, h)
      if h >= 0 && h <= 1; return [c, x, 0] end
      if h >= 1 && h <= 2; return [x, c, 0] end
      if h >= 2 && h <= 3; return [0, c, x] end
      if h >= 3 && h <= 4; return [0, x, c] end
      if h >= 4 && h <= 5; return [x, 0, c] end
      if h >= 5 && h <= 6; return [c, 0, x] end
      return [0, 0, 0]
    end

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
          # c = (1 - (2 * l -1).abs) * s
          # x = c * (1 - ((h1 % 2) - 1).abs)
          # rgb1 = hue_2_rgb(c, x, h1)
          # m = l - 0.5 * c
          rgb = [r, g, b]
      end

      rgb
    end

    def get_color_for_force(force)
      value = force.abs / 100.0 # [0N, 100N] => [0, 0.5]
      value = 1 if value > 1
      value = 0 if value < 0
      # strong negative force will be blue (stretching), strong positive force
      # will be red (compression)
      h = force <= 0 ? 200.0 : 360.0 #(1.0 - value) * 360.0
      s = 1
      l = 1 - value

      hsl_to_rgb(h, s, l)
    end
  end
end
