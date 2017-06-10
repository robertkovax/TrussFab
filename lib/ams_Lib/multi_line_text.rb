# MultiLineText is a simple SketchUp text wrapped with custom methods that
# make it easy for the user to log information on screen.
# @since 2.0.0
class AMS::MultiLineText

  # Create a new MultiLineText object.
  # @param [Integer] x X position.
  # @param [Integer] y Y position.
  def initialize(x = 10, y = 10)
    @text = []
    @entity = nil
    @limit = 20
    @count = 0
    @pos = [x,y]
    @intro = ''
    @hl = '-' * 80
    @show_line_numbers = true
  end

  # @!attribute [r] count
  #   Get line count.
  #   @return [Fixnum]

  # @!attribute [r] entity
  #   Get text entity.
  #   @return [Sketchup::Text]


  attr_reader :count, :entity

  private

  def add_text(text = '')
    model = Sketchup.active_model
    view = model.active_view
    w = view.vpwidth
    h = view.vpheight
    hr = @pos[0]/w.to_f
    vr = @pos[1]/h.to_f
    @entity = model.add_note(text, hr, vr)
  end

  def update
    add_text if is_deleted?
    if @text.size > @limit
      @text[0, (@text.size - @limit)] = nil
      @text.compact!
    end
    size = @text.size
    t = ""
    for i in 0...size
      t += sprintf("[%03i]    ", @count-size+i+1) if @show_line_numbers
      t += @text[i].to_s + "\n"
    end
    if @intro.empty?
      @entity.text = t
    else
      @entity.text = "#{@hl}\n\n#{@intro}\n\n#{@hl}\n\n#{t}"
    end
    nil
  end

  def is_deleted?
    @entity.nil? or @entity.deleted?
  end

  public

  # Get line limit.
  # @return [Fixnum]
  def get_limit
    @limit
  end

  # Set line limit.
  # @param [Fixnum] value
  # @return [void]
  def set_limit(value)
    @limit = value.to_i
    @limit = 1 if value < 1
    @limit = 200 if value > 200
    update
  end

  # Get text title/top description.
  # @return [String]
  def get_intro
    @intro.dup
  end

  # Set text title/top description.
  # @param [String] str
  # @return [void]
  def set_intro(str = "")
    @intro = text.to_s
    update
  end

  # Show/Hide line numbers.
  # @param [Boolean] state
  # @return [void]
  def show_line_numbers(state)
    @show_line_numbers = (state == true)
    update
  end

  # Determine whether line numbers are visible.
  # @return [Boolean]
  def line_numbers_visible?
    @show_line_numbers
  end

  # Add text to the current line.
  # @param [String] str
  # @return [void]
  def print(str)
    @text.last.push(str.to_s)
    update
  end

  # Add text to the new line.
  # @param [String] str
  # @return [void]
  def puts(str)
    @count += 1
    @text.push(str.to_s)
    update
  end

  # Clear all data.
  # @return [void]
  def clear
    @text.clear
    @count = 0
    update
    nil
  end

  # Remove text object and clear all data.
  # @return [void]
  def remove
    if @entity.valid?
      @entity.material = nil
      @entity.erase!
    end
    @entity = nil
    @text.clear
    @count = 0
    nil
  end

end # class AMS::MultiLineText
