require 'singleton'

class IdManager
  include Singleton

  attr_reader :last_id

  def initialize
    @last_id = 0
    @tag_id_map = Hash.new { |h, k| h[k] = 0 }
  end

  def generate_next_id
    @last_id += 1
  end

  def generate_next_tag_id(tag)
    @tag_id_map[tag] += 1
  end
end
