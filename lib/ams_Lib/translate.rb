module AMS
  # Translate allows loading and controlling localization of strings.
  # @note This translate class is based on SketchUp langhadler.rb and
  #   AE::Translate by Andreas Eisenbarth.
  # @since 2.0.0
  class Translate

    # Load translation strings.
    # @param [String] toolname A name to identify the translation file (plugin
    #   name).
    # @param [String] dir An optional directory path where to search, otherwise in
    #   this file's directory.
    def initialize(toolname = nil, dir = nil)
    end

    private

    # Find translation file and parse it into a hash.
    # @param [String] toolname A name to identify the translation file
    #   (plugin name).
    # @param [String] locale The locale/language to look for.
    # @param [String] dir An optional directory path where to search, otherwise in
    #   this file's directory
    # @return [Boolean] Whether the strings have been added.
    def parse_strings(toolname = nil, locale = "en", dir = nil)
    end

    public

    # Get a single translation.
    # @param [String] key Original string in ruby script; % characters escaped by
    #   %%.
    # @param [*String] si s0-sn: optional strings for substitution of %0 ... %sn.
    # @return [String] translated string
    def get(key, *si)
    end

    alias_method(:[], :get)

    # Get all translations as hash.
    # @return [Hash{String => String}] key/value pairs of original and translated
    #   strings.
    def get_all
    end

  end # class Translate
end # module AMS
