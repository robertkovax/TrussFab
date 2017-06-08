# This namespace contains functions associated with the MIDI output interface.
# @since 2.0.0
# @note All methods below were made compatible with Mac OS X since 3.4.0 unless
#   otherwise stated.
module AMS::MIDI
  class << self

    # Get handle to an open MIDI device.
    # @return [Fixnum, nil]
    # @since 3.0.0
    def get_device_handle
    end

    # Determine whether the device is open.
    # @return [Boolean]
    # @since 3.4.0
    def is_device_open?
    end

    # Open MIDI device.
    # @return [Boolean] success
    def open_device
    end

    # Close MIDI device.
    # @return [Boolean] success
    def close_device
    end

    # Send MIDI message.
    # @return [Boolean] success
    # @overload out_message(arg0, arg1, arg2)
    #   @param [Fixnum] arg0 A value between 0 and 127.
    #   @param [Fixnum] arg1 A value between 0 and 127.
    #   @param [Fixnum] arg2 A value between 0 and 127.
    # @overload out_message(arg0, arg1)
    #   @param [Fixnum] arg0 A value between 0 and 127.
    #   @param [Fixnum] arg1 A value between 0 and 127.
    # @overload out_message(arg0)
    #   @param [Fixnum] arg0 A value between 0 and 127.
    # @since 3.4.0
    def out_message(*args)
    end

    # Get volume of both channels.
    # @return [Array<Numeric>, nil] +[left, right]+ Each value is between 0.00
    #   and 1.00. This function returns +nil+ if MIDI device is invalid or not
    #   open.
    # @note Doesn't work on Mac OS X; return <tt>[1.0, 1.0]</tt>
    def get_volume
    end

    # @overload set_volume(left, right)
    #   Set volume of each channel.
    #   @param [Numeric] left This value is clamped between 0.0 and 1.0.
    #   @param [Numeric] right This value is clamped between 0.0 and 1.0.
    #   @return [Boolean] success
    # @overload set_volume(volume)
    #   Apply same volume to both channels.
    #   @param [Numeric] volume This value is clamped between 0.0 and 1.0.
    #   @return [Boolean] success
    def set_volume(*args)
    end

    # Stop all playing notes.
    # @return [Boolean] success
    def reset
    end

    # Play MIDI note.
    # @note Setting channel to 9 will play midi notes from the "General MIDI
    #   Percussion Key Map." Any other channel will play midi notes from the
    #   "General MIDI Instrument Patch Map". If channel is set to 9, the
    #   instrument parameter will have no effect and the note parameter will be
    #   used to play particular percussion sound, if note's value is between 27
    #   and 87. According to my experiments, values outside that 27-87 range
    #   won't yield any sounds.
    # @note Some instruments have notes that never seem to end. For this reason
    #   it might come in handy to use {stop_note} function when needed.
    # @param [Fixnum] instrument A value between 0 and 127. See link below for
    #   supported instruments and their identifiers.
    # @param [Fixnum] note A value between 0 and 127. Each instrument has a
    #   maximum of 128 notes.
    # @param [Fixnum] channel A value between 0 and 15. Each note has a maximum
    #   of 16 channels. To play multiple sounds of same type at the same time,
    #   change channel value to an unused one. Remember that channel 9 is
    #   subjected to different instrument patch and it will change the behaviour
    #   of this function; see note above.
    # @param [Fixnum] volume A value between 0 and 127. 0 means quiet/far and
    #   127 means close/loud.
    # @return [Fixnum, nil] Midi note ID or nil if MIDI interface failed to play
    #   the note.
    # @see http://wiki.fourthwoods.com/midi_file_format#general_midi_instrument_patch_map General MIDI Instrument Patch Map
    # @since 3.0.0
    def play_note(instrument, note, channel = 0, volume = 127)
    end

    # Stop MIDI note.
    # @param [Fixnum] id A MIDI note identifier returned by the
    #   {play_note} function. Pass -1 to stop all midi notes.
    # @return [Boolean] success
    # @since 3.0.0
    def stop_note(id)
    end

    # Set MIDI note position in 3D space.
    # @note Sound volume and panning is not adjusted automatically with respect
    #   to camera orientation. It is required to manually call this function
    #   every frame until the note is stopped or has finished playing. Sometimes
    #   it's just enough to call this function once after playing the note.
    #   Other times, when the note is endless or pretty long, it might be useful
    #   to update position of the note every frame until the note ends or is
    #   stopped. Meantime, there is no function to determine when the note ends.
    #   It is up to the user to decide for how long to call this function or
    #   when to stop calling this function.
    # @note When it comes to setting 3D positions of multiple sounds, make sure
    #   to play each sound on separate channel. That is, play sound 1 on channel
    #   0, sound 2 on channel 1, sound 3 on channel 2, and etcetera until
    #   channel gets to 15, as there are only 15 channels available. Read the
    #   note below to find out why each sound is supposed to be played on
    #   separate channel. I think it would make more sense if the function was
    #   renamed to <tt>set_channel_position</tt> and had the 'id' parameter
    #   replaced with 'channel'.
    # @note This function works by adjusting panning and volume of the note's
    #   and instrument's channel, based on camera's angle and distance to the
    #   origin of the sound. Now, there is only one function that adjusts stereo
    #   and panning, but it adjusts panning and volume of all notes and
    #   instruments that are played on same channel. As of my research, I
    #   haven't found a way to adjust panning and volume of channel that belongs
    #   to particular note and instrument. There's only a function that can
    #   adjust panning and volume of channel that belongs to all notes and
    #   instruments that are played on particular channel. For instance, if you
    #   play instrument 1 and instrument 2, both on channel zero, they will still
    #   play simultaneously, without cancelling out each other, as if they are
    #   playing on separate channels, but when it comes to adjusting panning and
    #   volume of one of them, the properties of both sounds will be adjusted.
    #   This means that this function is only limited to playing 16 3D sounds,
    #   with each sound played on different channel. Otherwise, sounds played on
    #   same channel at different locations, will endup being tuned as if they
    #   are playing from the same location.
    # @param [Fixnum] id A MIDI note identifier returned by the
    #   {play_note} function.
    # @param [Geom::Point3d, Array<Numeric>] pos MIDI note position in global
    #   space.
    # @param [Numeric] max_hearing_range MIDI note maximum hearing range in
    #   meters.
    # @return [Boolean] success
    # @since 3.0.0
    def set_note_position(id, pos, max_hearing_range)
    end

    # Set note controller.
    # @param [Fixnum] channel A value between 0 and 15.
    # @param [Fixnum] cnum Controller number, a value between 0 and 127.
    # @param [Fixnum] cval Controller value, a value between 0 and 127.
    # @return [Boolean] success
    # @see http://wiki.fourthwoods.com/midi_file_format#controller_codes MIDI Controller Codes
    def change_channel_controller(channel, cnum, cval)
    end

    # Set channel volume.
    # @param [Fixnum] channel A value between 0 and 15.
    # @param [Fixnum] volume A value between 0 (soft) and 127 (loud).
    # @return [Boolean] success
    def change_channel_volume(channel, volume)
    end

    # Distribute channel volume between left and right speakers.
    # @param [Fixnum] channel A value between 0 and 15.
    # @param [Fixnum] pan A value between 0 and 127. 0 is far left, 64 is
    #  center, and 127 is far right.
    # @return [Boolean] success
    def change_channel_stereo_pan(channel, pan)
    end

    # Set channel expression. This is used for dynamics within a single track.
    # @param [Fixnum] channel A value between 0 and 15.
    # @param [Fixnum] expression A value between 0 and 127.
    # @return [Boolean] success
    def change_channel_expression(channel, expression)
    end

    # Control channel pedal.
    # @note Message must be sent prior to the note it affects.
    # @param [Fixnum] channel A value between 0 and 15.
    # @param [Boolean] state +true+ for pedal down; +false+ for pedal up.
    # @return [Boolean] success
    # @since 3.0.0
    def sustain_channel_pedal(channel, state)
    end

    # Reset channel controllers.
    # @param [Fixnum] channel A value between 0 and 15.
    # @return [Boolean] success
    def reset_channel_controllers(channel)
    end

    # Change channel program.
    # @param [Fixnum] channel A value between 0 and 15.
    # @param [Fixnum] instrument A value between 0 and 127.
    # @return [Boolean] success
    # @since 3.3.0
    def change_channel_instrument(channel, instrument)
    end

    # Turn on MIDI note.
    # @param [Fixnum] channel A value between 0 and 15.
    # @param [Fixnum] note A value between 0 and 127. Each instrument has a
    #   maximum of 128 notes.
    # @param [Fixnum] volume A value between 0 (soft) and 127 (loud).
    # @return [Boolean] success
    # @since 3.3.0
    def play_note2(channel, note, volume)
    end

    # Turn off MIDI note.
    # @param [Fixnum] channel A value between 0 and 15.
    # @param [Fixnum] note A value between 0 and 127. Each instrument has a
    #   maximum of 128 notes.
    # @param [Fixnum] volume A value between 0 (soft) and 127 (loud).
    # @note The volume parameter isn't logically necessary to stop a note, but
    #   it could be used to fade out the note. Pass zero to stop the note
    #   immediately.
    # @return [Boolean] success
    # @since 3.3.0
    def stop_note2(channel, note, volume)
    end

    # Set channel position in 3d space.
    # @note Same as {set_note_position} but takes channel instead of id as
    #   parameter.
    # @param [Fixnum] channel A value between 0 and 15.
    # @param [Geom::Point3d, Array<Numeric>] pos MIDI note position in global
    #   space.
    # @param [Numeric] max_hearing_range MIDI note maximum hearing range in
    #   meters.
    # @return [Boolean] success
    # @since 3.3.0
    def change_channel_position(channel, pos, max_hearing_range)
    end

  end # class << self
end # module AMS::MIDI
