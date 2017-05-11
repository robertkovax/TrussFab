require 'digest'

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

  def changed_rb_files
    rb_files.select { |filename| changed?(filename) }
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
    changed_files = changed_rb_files
    mute_warnings do
      changed_files.each do |filename|
        store_digest(filename)
        load(filename)
      end
    end
    if $VERBOSE
      puts "Reloaded #{changed_files.size} files"
      changed_files.each { |filename| puts(filename) } #unless changed_files.empty?
    end
    changed_files.size
  end
end
