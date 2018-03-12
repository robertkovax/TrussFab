require 'digest'

require 'truss_fab.rb'

class Reloader
  def initialize
    @file_digests = {}
    store_digests
  end

  def compute_digest(filename)
    Digest::SHA256.file(filename)
  end

  def store_digest(filename)
    digest = compute_digest(filename)
    @file_digests[filename] = digest
  end

  def store_digests
    rb_files.each { |filename| store_digest(filename) }
    frontend_files.each { |filename| store_digest(filename) }
  end

  def changed?(filename)
    @file_digests.include?(filename) &&
      compute_digest(filename) != @file_digests[filename]
  end

  # Finds and returns the filename for each of the root .rb files in the
  # tutorials folder.
  #
  # @return [Array<String>] files
  def rb_files
    src_path = File.join(__dir__, 'src')
    file_pattern = File.join(src_path, '**', '*.rb')
    Dir.glob(file_pattern)
  end

  def find_changed_rb_files
    rb_files.select { |filename| changed?(filename) }
  end

  def frontend_files
    src_path = File.join(__dir__, 'src')
    file_pattern_js = File.join(src_path, '**', '*.js')
    file_pattern_html = File.join(src_path, '**', '*.html')
    file_pattern_erb = File.join(src_path, '**', '*.erb')
    file_pattern_css = File.join(src_path, '**', '*.css')

    Dir.glob([file_pattern_js, file_pattern_html, file_pattern_erb, file_pattern_css]).reject {|fn| fn.include? 'node_modules'}
  end

  def find_changed_frontend_file
    frontend_files.select { |filename| changed? filename }
  end

  # Utility method to mute Ruby warnings for whatever is executed by the block.
  def mute_warnings
    old_verbose = $VERBOSE
    $VERBOSE = nil
    result = yield
  ensure
    $VERBOSE = old_verbose
    result
  end

  # Utility method to quickly reload the tutorial files. Useful for development.
  #
  # @return [Integer] Number of files reloaded.
  def reload
    changed_rb_files = find_changed_rb_files
    changed_frontend_files = find_changed_frontend_file
    mute_warnings do
      changed_rb_files.each do |filename|
        store_digest(filename)
        load(filename)
      end
      changed_frontend_files.each do |filename|
        store_digest(filename)
      end
      TrussFab.refresh_ui unless changed_frontend_files.empty?
    end
    if $VERBOSE
      puts "Reloaded #{changed_rb_files.size} files"
      changed_rb_files.each { |filename| puts(filename) }
    end
    puts ".rb: #{changed_rb_files.size} .html/.js/.css: #{changed_frontend_files.size}"
  end
end
