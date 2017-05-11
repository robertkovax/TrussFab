require 'singleton'

class IdManager
  include Singleton

  attr_reader :last_id

  def initialize
    @last_id = 0
  end

  def generate_next_id
    @last_id += 1
  end
end
