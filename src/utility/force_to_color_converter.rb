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

    def hsl_to_rgb(h, s, l)
       r = 0
       g = 0
       b = 0

      if s == 0
          r = g = b = l;
      else
          c = (1 - (2 * l -1).abs) * s
          h1 = h/60
          x = c * (1 - ((h1 % 2) - 1).abs)
          rgb1 = hue_2_rgb(c, x, h1)
          m = l - 0.5 * c
          rgb = [(rgb1[0] + m) * 255, (rgb1[1] + m) * 255, (rgb1[2] + m) * 255]
      end

      rgb;
    end

    def get_color_for_force(force)
      g = force / 9.80
      value = (g + 5) / 10 # [-5g, 5g] => [0, 1]
      h = (1 - value) * 360
      s = 1
      l = value * 0.5

      hsl_to_rgb(h, s, l)
    end
  end
end
