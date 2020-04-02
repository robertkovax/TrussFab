require 'gsl'

def is_matrix(line)
  /^  parameter Real [A-D]/.match(line)
end

def is_label(line)
  /^  Real/.match(line)
end

class LinearStateSpaceModel
  def initialize(path)
    File.readlines(path).each do |line|
      # TODO parse initial condition
      if is_label(line)
        # TODO parse lables
        puts line
      elsif is_matrix(line)
        matrix_name, matrix_data = /^  parameter Real ([A-D]).*= \[(.*)\];$/.match(line).captures
        puts matrix_data
        mat = line.split("; ").map{|row| row.split(", ").map{ |cell| cell.to_f }.to_gv}
        # TODO finishe GSL to Matrix parsing
      end
    end
  end
end
