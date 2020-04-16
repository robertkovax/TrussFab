include Math
require 'gsl'


class LinearStateSpaceModel
  def initialize(path)

    File.readlines(path).each do |line|
      # TODO parse initial condition
      if LinearStateSpaceModel.is_matrix(line)

        is_zero = false
        line_match = /^  parameter Real (?<matrix_name>[A-D]).*= \[(?<matrix_data>.*)\];$/.match(line)
        if line_match
          mat = line_match[:matrix_data].split("; ").map{|row| row.split(", ").map{ |cell| cell.to_f }}
          store_matrix(line_match[:matrix_name], GSL::Matrix[*mat])
        else
          # if a normal match cannot be made we will check whether it is a empty matrix
          line_match = /^  parameter Real (?<matrix_name>[A-D]).*= zeros\(., .\);$/.match(line)
          if line_match
            is_zero = true
          else
            raise "Invalid Matrix format in linearized Modelica output file"
          end
        end
          # TODO generate zero matrices
      elsif LinearStateSpaceModel.is_vector(line)
        line_match = /^  parameter Real (?<vector_name>[ux]0).*= \{(?<vector_data>.*)\};$/.match(line)
        vec = line_match[:vector_data].split(', ').map{|cell| "%f" % cell.to_f }
        store_vector(line_match[:vector_name], GSL::Vector[*vec])
      elsif LinearStateSpaceModel.is_label(line)
        line_match = /^  Real \'(?<label_name>.*)\' = (?<label_category>[ux])\[(?<label_number>\d+)\];/.match(line)
      end
    end
  end

  def eigenfreq
    val, vec = @A.eigen_nonsymm
    p val.to_a
    p vec.to_a

    # f = GSL::Vector.linspace(0, 100, val.size)
    GSL::graph(val.re, val.im, "-C -g 3")
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
