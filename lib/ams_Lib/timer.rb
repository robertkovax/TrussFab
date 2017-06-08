# The Timer namespace contains functions that are associated with Windows timer.
# Unlike the <tt>UI.start_timer</tt>/<tt>UI.stop_timer</tt> functions,
# AMS::Timer has timeout parameter in milliseconds, it properly stops if repeat
# is false and the messagebox is called within it, and it yields information to
# a timer procedure which might be handy.
# @since 2.0.0
# @note Windows only!
module AMS::Timer
  class << self

    # Create a timed procedure.
    # @param [Fixnum] time_out Time out in milliseconds. Minimum elapse is
    #   0x0000000A (10) milliseconds; maximum elapse is 0x7FFFFFFF (2147483647)
    #   milliseconds.
    # @param [Boolean] repeat Whether to repeat the timer.
    # @yieldparam [Fixnum] count The number of times the timer was called.
    # @yieldparam [Fixnum] time Current time.
    # @return [Fixnum, nil] Timer ID if successful.
    # @see https://msdn.microsoft.com/en-us/library/windows/desktop/ms644906(v=vs.85).aspx SetTimer
    def start(time_out, repeat, &block)
    end

    # Kill the specified timed procedure.
    # @param [Fixnum] id Timer ID
    # @return [Boolean] success
    # @see https://msdn.microsoft.com/en-us/library/windows/desktop/ms644903(v=vs.85).aspx KillTimer
    def stop(id)
    end

  end # class << self
end # module AMS::Timer
