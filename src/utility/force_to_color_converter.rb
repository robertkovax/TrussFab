# Convert a force in Newton to a color
class ColorConverter
  class << self
    def convert_temp_color(t_color, t_1, t_2)
      t_color += 1 if t_color < 0
      t_color -= 1 if t_color > 1
      color = 0
      if 6 * t_color < 1
        color = t_2 + (t_1 - t_2) * 6 * t_color
      elsif 2 * t_color < 1
        color = t_1
      elsif 3 * t_color < 2
        color = t_2 + (t_1 - t_2) * (2.0/3.0 - t_color) * 6
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
        t_1 = l < 0.5 ? (l * (1.0 + s)) : (l + s - l * s)
        t_2 = 2 * l - t_1

        h1 = h/360.0

        t_r = h1 + 1.0/3.0

        t_g = h1

        t_b = h1 - 1.0/3.0

        r = (convert_temp_color(t_r, t_1, t_2) * 255).round
        g = (convert_temp_color(t_g, t_1, t_2) * 255).round
        b = (convert_temp_color(t_b, t_1, t_2) * 255).round

        rgb = "##{"%02X" % r}#{"%02X" % g}#{"%02X" % b}"
      end

      return rgb
    end

    def get_color_for_force(force)
      # scale the force to a scale of [0, 0.5] for 0 - ± maxForce
      # capped at 0.5, because at half lightness, the selected color looks
      # the "most vibrant" in HSL
      # no force will have a value of 0, which gives us a lightness value of 1,
      # which is always white
      value = force.abs / 1500.0
      value = 0.3 if (value > 0.3)
      value = 0 if value < 0
      value = 0.5 if force.abs >= 1500

      # strong negative force will be blue (stretching), strong positive force
      # will be red (compression)
      # In HSL, a hue value of 200 degrees is a light blue color, 360 degrees is red
      h = force <= 0 ? 200.0 : 0.0
      s = 1
      l = 1 - value

      return hsl_to_rgb(h, s, l)
    end
  end
end
