require 'singleton'

class IdManager
  include Singleton

  def initialize
    @last_id = 0
  end

  def get_last_id
    @last_id
  end

  def generate_next_id
    @last_id += 1
    @last_id
  end
end