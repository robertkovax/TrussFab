
class Float
  def round_to n = 0
    (self * 10**n).round / 10.0**n
  end
end

class FourierTransform
  attr_reader :spectrum, :bandwidth, :samplerate, :buffersize

  def initialize buffersize, samplerate
    @buffersize = buffersize
    @samplerate = samplerate
    @bandwidth = (2.0 / @buffersize) * (@samplerate / 2.0)
    @spectrum = Array.new

    build_reverse_table
    build_trig_tables
  end

  def build_reverse_table
    @reverse = Array.new(@buffersize)
    @reverse[0] = 0;

    limit = 1
    bit = @buffersize >> 1

    while (limit < @buffersize )
      (0...limit).each do |i|
        @reverse[i + limit] = @reverse[i] + bit
      end

      limit = limit << 1
      bit = bit >> 1
    end
  end

  def build_trig_tables
    @sin_lookup = Array.new(@buffersize)
    @cos_lookup = Array.new(@buffersize)
    (0...@buffersize).each do |i|
      @sin_lookup[i] = Math.sin(- Math::PI / i);
      @cos_lookup[i] = Math.cos(- Math::PI / i);
    end
  end

  def dft(buffer)
    real = Array.new(buffer.length/2, 0)
    imag = Array.new(buffer.length/2, 0)

    (0...buffer.length/2).each do |k|
      (0...buffer.length).each do |n|
        real[k] += buffer[n] * Math.cos(2 * Math::PI * k * n / buffer.length)
        imag[k] += buffer[n] * -Math.sin(2 * Math::PI * k * n / buffer.length)
      end
      @spectrum[k] = 2 * Math.sqrt(real[k] ** 2 + imag[k] ** 2) / buffer.length
    end

    @spectrum
  end

  def fft(buffer)
    raise Exception if buffer.length % 2 != 0

    real = Array.new(buffer.length)
    imag = Array.new(buffer.length)

    (0...buffer.length).each do |i|
      real[i] = buffer[@reverse[i]]
      imag[i] = 0.0
    end

    # here begins teh Danielson-Lanczos section
    halfsize = 1
    while halfsize < buffer.length
      #k = - Math::PI / halfsize
      #phase_shift_step_real = Math.cos(k)
      #phase_shift_step_imag = Math.sin(k)
      phase_shift_step_real = @cos_lookup[halfsize]
      phase_shift_step_imag = @sin_lookup[halfsize]
      current_phase_shift_real = 1.0
      current_phase_shift_imag = 0.0
      (0...halfsize).each do |fft_step|
        i = fft_step
        while i < buffer.length
          off = i + halfsize
          tr = (current_phase_shift_real * real[off]) - (current_phase_shift_imag * imag[off])
          ti = (current_phase_shift_real * imag[off]) + (current_phase_shift_imag * real[off])
          real[off] = real[i] - tr
          imag[off] = imag[i] - ti
          real[i] += tr
          imag[i] += ti

          i += halfsize << 1
        end
        tmp_real = current_phase_shift_real
        current_phase_shift_real = (tmp_real * phase_shift_step_real) - (current_phase_shift_imag * phase_shift_step_imag)
        current_phase_shift_imag = (tmp_real * phase_shift_step_imag) + (current_phase_shift_imag * phase_shift_step_real)
      end

      halfsize = halfsize << 1
    end

    (0...buffer.length/2).each do |i|
      @spectrum[i] = 2 * Math.sqrt(real[i] ** 2 + imag[i] ** 2) / buffer.length
    end

    @spectrum
  end

  def index_to_frequency(i)
    i * @bandwidth
  end

  def frequency_to_index(freq)
    (@buffersize.to_f * (freq / @samplerate)).round
  end

  def peak_frequency
    index = (0...spectrum.length).max {|a, b| spectrum[a] <=> spectrum[b] }
    index_to_frequency(index)
  end

  def plot(rows = 20, cols = 80)
    return if @spectrum.empty?

    max = @spectrum.max
    min = @spectrum.min
    y = (max - min) / rows.to_f
    bandwidth = cols / @spectrum.length
    rows.downto(0).each do |row|
      line = ""
      (0...@spectrum.length).each do |col|
        if row == 0
          line << "-"
        elsif @spectrum[col].round_to(1) >= (row * y).round_to(1)
          line << "."
        else
          line << " "
        end
      end
      if row % 2 == 0
        line << "- #{sprintf "%.1f", row * y}"
      end

      puts line
    end

    # Draw Freq arrows
    line = ""
    (0..@spectrum.length).each do |i|
      if @spectrum[i] == max
        line << "*"
      elsif i % 10 == 0
        line << "^"
      else
        line << " "
      end
    end
    puts line

    # Draw Frequency labels
    line = ""
    (0..@spectrum.length).each do |col|
      if col % 10 == 0
        label = "#{(col * @bandwidth).round}Hz"
        if col == 0
          line << label
        else
          line = line.chop << label + " "
        end
        (0...(10-label.length)).each do
          line << " "
        end
      end
    end
    puts line
  end
end
