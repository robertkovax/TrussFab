module Debug
  class << self
    def log_time(msg = nil, &block)
      before = Time.now
      yield
      after = Time.now
      span = after - before
      print msg + ' - ' unless msg.nil?
      puts span
    end
  end
end