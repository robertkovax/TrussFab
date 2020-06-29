require 'gsl'

class LinearStateSpaceModel
  ##
  # This class represents (in control theory terms) a (MIMO) system that has been linarized
  # A system here is a entity that takes one or multiple time-series as inputs and returns one
  # or multiple time series
  #
  # Linearization is a process where all non-linear equations are approximated with a
  # linar representation to be able to conduct further analysis
  #
  # Every Linear Model is defined by 4 matricies and 2 Vectors:
  # A: System Matrix (governs how the model behaves ie. how internal states are changing themselves)
  # B: Input Matrix (governs how the input influences the system)
  # C: Ouput Matrix (how the internal states translte into the output)
  # D: Passtrhough Matrix (used if inputs can directly alter outputs (seldom in this use-case))
  # vector u0: Initial/default inputs
  # vector x0: Initial conditions of the internal states
  #
  # The class is created by parsing the result of a Modelica linarization (see SimulationRunner)
  # This file also contains semantic labels to make sense of inputs, outputs and internal states.

  def initialize(path)

    modelica_file_content = File.read(path)

    # put every field into its own line
    modelica_file_content = modelica_file_content.gsub("\n\t", " ")

    modelica_file_content.split("\n").each do |line|
      if LinearStateSpaceModel.is_matrix(line)

        is_zero = false
        line_match = /^  parameter Real (?<matrix_name>[A-D]).*= \[(?<matrix_data>.*)\];$/.match(line)
        if line_match
          mat = line_match[:matrix_data].split("; ").map{|row| row.split(", ").map{ |cell| cell.to_f }}
          store_matrix(line_match[:matrix_name], Matrix[*mat])
        else
          raise "Invalid Matrix format in linearized Modelica output file"
        end
      elsif LinearStateSpaceModel.is_vector(line)
        line_match = /^  parameter Real (?<vector_name>[ux]0).*= \{(?<vector_data>.*)\};$/.match(line)
        vec = line_match[:vector_data].split(', ').map{|cell| cell.to_f }
        store_vector(line_match[:vector_name], vec)
      elsif LinearStateSpaceModel.is_label(line)
        line_match = /^  Real \'(?<label_name>.*)\' = (?<label_category>[ux])\[(?<label_number>\d+)\];/.match(line)
      end
    end
  end

  def eigenfreq
    val, vec = GSL::Matrix(@A).eigen_nonsymm
    p val.to_a
    p vec.to_a

    # f = GSL::Vector.linspace(0, 100, val.size)
    GSL::graph(val.re, val.im, "-C -g 3")
  end

  def bode_plot
    # The bode plot gives us more information about the frequency response of the system
    # it consits of two sub-plots:magnitude plot (how the system alters the magintude of the frequencies) &
    # phase plot (how the phase is altered at a given frequency)
    #
    # https://en.wikipedia.org/wiki/Bode_plot#Definition

    frequencies = (-3..3).step(0.1).to_a.map { |a| 10**a }

    def transfer_function(s)
      # https://stackoverflow.com/a/26607715
      i = Matrix.identity(@A.row_count)
      (@C * (s * i - @A).inverse * @B + @D)[0,0]

    end

    frequency_response = frequencies.map{|w| transfer_function(Complex(0, w))}

    {:frequencies => frequencies, :magnitude => frequency_response.map{ |c| Complex(c).abs }, :phase => frequency_response.map{ |c| Complex(c).arg } }
  end

  def cp_to_python
    puts "A = #{@A.to_a}"
    puts "B = #{@B.to_a}"
    puts "C = #{@C.to_a}"
    puts "x0 = #{@x0.to_a}"
    puts "u0 = #{@u0.to_a}"
  end

  def check_input(input_vector)
    @A * @x0 == @B * input_vector
  end

  def store_vector(identifyer, vector)
    if identifyer == 'x0'
      @x0 = vector
    elsif identifyer == 'u0'
      @u0 = vector
    end
  end

  def store_matrix(identifyer, matrix)
    if identifyer == 'A'
      @A = matrix
    elsif identifyer == 'B'
      @B = matrix
    elsif identifyer == 'C'
      @C = matrix
    elsif identifyer == 'D'
      @D = matrix
    end
  end

  def self.is_matrix(line)
    /^  parameter Real [A-D]/.match?(line)
  end

  def self.is_vector(line)
    /^  parameter Real [ux]0/.match?(line)
  end

  def self.is_label(line)
    /^  Real \'/.match?(line)
  end
end
