# MultiLineText is a SketchUp text wrapped with custom methods for logging
# information.
# @note Many of the functions that make a change influence the undo stack. Wrap
#   them with a start/commit operation when/if desired.
# @note Since 3.5.0, when/if a MultiLineText object is garbage collected, the
#   associated text entity is erased.
# @note Since 3.5.0, cloning a MultiLineText object now creates a new text
#   entity, rather than linking to the original one.
# @since 2.0.0
class AMS::MultiLineText

  # Create a new MultiLineText object.
  # @param [Fixnum] x The horizontal position in pixels from the upper-left
  #   corner of the viewport.
  # @param [Fixnum] y The vertical position in pixels from the upper-left
  #   corner of the viewport.
  def initialize(x,y)
  end

  # Get entity associated with the text.
  # @return [Sketchup::Text, nil]
  # @since 3.5.0
  def get_entity
  end

  # Set entity associated with the text.
  # @param [Sketchup::Text] entity
  # @return [nil]
  # @since 3.5.0
  def set_entity(entity)
  end

  # Get screen position of the associated text entity.
  # @note If the associated text entity is moved, the position remains unchanged
  #   until {set_position} is called.
  # @return [Array<(Fixnum, Fixnum)>] +[x,y]+ The text position from the
  #   upper-left corner of the viewport.
  # @since 3.5.0
  def get_position
  end

  # Set screen position of the associated text entity.
  # @note If the associated text entity is not locked to screen, this function
  #   stores the positions but does not move the entity.
  # @note Since moving Sketchup::Text requires some workarounds, this function
  #   closes the activate entity path, for a proper operation.
  # @note Wrap this function with a start/commit operation block.
  # @param [Fixnum] x The horizontal position in pixels from the upper-left
  #   corner of the viewport.
  # @param [Fixnum] y The vertical position in pixels from the upper-left
  #   corner of the viewport.
  # @return [nil]
  # @since 3.5.0
  def set_position(x,y)
  end

  # Get line limit.
  # @return [Fixnum]
  def get_limit
  end

  # Set line limit.
  # @param [Fixnum] limit A value between 1 and 1000.
  # @return [nil]
  def set_limit(limit)
  end

  # Get text title/top description.
  # @return [String]
  def get_intro
  end

  # Set text title/top description.
  # @param [String] intro
  # @return [nil]
  def set_intro(intro)
  end

  # Show/hide line numbers.
  # @param [Boolean] state
  # @return [nil]
  def show_line_numbers(state)
  end

  # Determine whether line numbers are visible.
  # @return [Boolean]
  def line_numbers_visible?
  end

  # Add text to the current line.
  # @param [String] str
  # @return [nil]
  def print(str)
  end

  # Add text to the new line.
  # @param [String] str
  # @return [nil]
  def puts(str)
  end

  # Clear all data.
  # @return [nil]
  def clear
  end

  # Remove text object and reset all data.
  # @return [nil]
  def remove
  end

  # Get number of lines logged to screen.
  # @return [Fixnum]
  def count
  end

end # class AMS::MultiLineText
