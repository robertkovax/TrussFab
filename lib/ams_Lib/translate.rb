# Translate class allows user to simply load and control locilazation of their
# strings. This translate class is based on SketchUp langhadler.rb and
# AE::Translate by Andreas Eisenbarth.
# @since 2.0.0
class AMS::Translate

  # Load translation strings.
  # @param [String] toolname A name to identify the translation file (plugin
  #   name).
  # @param [String] dir An optional directory path where to search, otherwise in
  #   this file's directory.
  def initialize(toolname = nil, dir = nil)
    @strings = {}
    locale = Sketchup.get_locale
    parse_strings(toolname, "en", dir) if locale!="en" # as basis
    parse_strings(toolname, locale, dir)
  end

  private

  # Find translation file and parse it into a hash.
  # @param [String] toolname A name to identify the translation file (plugin
  #   name).
  # @param [String] locale The locale/language to look for.
  # @param [String] dir An optional directory path where to search, otherwise in
  #   this file's directory
  # @return [Boolean] Whether the strings have been added.
  def parse_strings(toolname = nil, locale = "en", dir = nil)
    toolname = "" if toolname.nil?
    unless toolname.is_a?(String)
      raise(ArgumentError, "Argument 'toolname' needs to be a String!", caller)
    end
    unless locale.is_a?(String)
      raise(ArgumentError, "Argument 'locale' needs to be a String")
    end
    unless dir.is_a?(String) || dir.nil?
      raise(ArgumentError, "Argument 'dir' needs to be a String")
    end

    dir = File.dirname(File.expand_path(__FILE__)) if dir.nil? || !File.exists?(dir.to_s)
    language = locale #locale[/^[^\-]+/]
    extensions = ['strings', 'lingvo', 'rb']

    available_files = Dir.entries(dir).find_all{ |f|
      File.basename(f)[/(^|#{toolname}[^a-zA-Z]?)#{locale}\.(#{extensions.join('|')})/i]
    }.concat(Dir.entries(dir).find_all{ |f|
      File.basename(f)[/(^|#{toolname}[^a-zA-Z]?)#{language}(-\w{2,3})?\.(#{extensions.join('|')})/i]
    })
    return if available_files.empty?
    path = File.join(dir, available_files.first)
    format = File.extname(path)[/[^\.]+/]
    strings = {}
    File.open(path, 'r'){ |file|
      # load .rb format
      if format == 'rb'
        strings = eval(file.read)
      # parse .strings or .lingvo format
      else
        entry = ""
        inComment = false
        file.each{ |line|
          if !line.include?("//")
            if line.include?("/*")
              inComment = true
            end
            if inComment == true
              if line.include?("*/")
                inComment = false
              end
            else
              entry += line
            end
          end
          if format == "strings" && entry.include?(";") || format == "lingvo" && !entry.empty?
            keyvalue = entry.strip.gsub(/^\s*\"|\"\s*;$/, "").split(/\"\s*=\s*\"|\s*<==>\s*/)
            next unless keyvalue.length == 2
            key = keyvalue[0].gsub(/\\\"/, '"').gsub(/\\\\/, "\\")
            value = keyvalue[1].gsub(/\\\"/, '"').gsub(/\\\\/, "\\")
            strings[key] = value
            entry = ""
          end
        }
      end # if format
    }

    @strings.merge!(strings)
    return !strings.empty?
  end

  public

  # Get a single translation.
  # @param [String] key Original string in ruby script; % characters escaped by
  #   %%.
  # @param [*String] si s0-sn: optional strings for substitution of %0 ... %sn.
  # @return [String] translated string
  def get(key, *si)
    unless key.is_a?(String) || key.nil? || key.is_a?(Array) && key.grep(String).length == key.length
      raise(ArgumentError, "Argument 'key' must be a String or an array of Strings!", caller)
    end
    return key.map{|k| self.[](k, *si)} if key.is_a?(Array) # Allow batch translation of strings
    value = (@strings[key] || key).to_s.clone
    # Substitution of additional strings.
    si.compact.each_with_index{|s, i|
      value.gsub!(/\%#{i}/, s.to_s)
    }
    value.gsub!(/\%\%/,"%")
    return value.chomp
  end

  alias_method(:[], :get)


  # Get all translations as hash.
  # @return [Hash{String => String}] key/value pairs of original and translated
  #   strings.
  def get_all
    return @strings
  end

end # class AMS::Translate
