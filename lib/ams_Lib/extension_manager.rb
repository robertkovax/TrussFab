begin
  require 'fileutils.rb'
rescue LoadError
  require File.join(AMS::Lib::PATH, 'thirdparty', 'fileutils.rb')
end

module AMS
  # An extension manager for copying, loading, and removing dynamic linked
  # libraries, C extensions, and rubies (credit to ThomThom).
  # @since 3.5.0
  class ExtensionManager

    # Apply a staging technique to the dynamically linked libraries, to avoid
    # experiencing overwrite issues that occur when attempting to update the
    # extension while it's loaded.
    # 1. The files within <i>EXT_PATH/libraries/stage/</i> folder are used as
    #    resources for copying and are not loaded. These files are the ones that
    #    get overwritten when the extension is updated.
    # 2. Unless already created, we create an additional version-specific folder
    #    within <i>EXT_PATH/libraries/</i> and copy all the necessary stage
    #    resources into the folder. The libraries within the version-specific
    #    folder are the ones that get loaded.
    # 3. In case the extension is installed outside the user directory, where the
    #    file permissions are limited, the necessary stage resources are copied
    #    into a TEMP folder and are loaded from there.
    # 4. An optional clean-up method removes outdated version-specific folders,
    #    and unregistered rubies, for the purpose of keeping the library clean.
    # @note When the libraries are copied, they are obtained from
    #   <i>EXT_PATH/libraries/stage/</i>.
    # @note When the libraries are loaded, they are obtained from
    #   <i>EXT_PATH/libraries/VERSION/</i> or
    #   <i>TEMP_EXT_PATH/libraries/VERSION/</i>.
    # @note Rubies are loaded from <i>EXT_PATH</i>.
    # @param [String] ext_path A path to the extension.
    # @param [String] ext_version A version of the extension.
    # @param [Boolean] experimental The experimental option updates the
    #   libraries every time they are loaded. This is useful if the library is
    #   in development.
    # @example
    #   dir = File.dirname(__FILE__)
    #   base = File.basename(__FILE__)
    #   ext_manager = AMS::ExtensionManager.new(dir, "1.2.3")
    #   ext_manager.add_c_extension('my_lib')
    #   ext_manager.add_ruby('some_ruby_file_name')
    #   ext_manager.add_ruby('some_other_ruby_file_name')
    #   ext_manager.add_ruby_no_require(base)
    #   ext_manager.require_all
    #   ext_manager.clean_up(true)
    def initialize(ext_path, ext_version, experimental = false)
      @ext_path = ext_path.to_s.dup
      @ext_version = ext_version.to_s.dup
      @experimental = experimental ? true : false
      unless AMS::IS_RUBY_VERSION_18
        @ext_path.force_encoding('UTF-8')
        @ext_version.force_encoding('UTF-8')
      end
      if @ext_version.empty? || @ext_version.gsub(/[^A-Za-z0-9\.\-]/i, '') != @ext_version
        raise(IOError, "The given extension version, \"#{@ext_version}\", is invalid!")
      end
      unless ::File.directory?(@ext_path)
        raise(IOError, "The given extension path, \"#{@ext_path}\", is invalid!")
      end
      @ext_name = ::File.basename(@ext_path)
      @c_extensions = []
      @libraries = []
      @rubies = []
      @rubies_no_require = []
    end

    # Add a C extension file that must be copied/loaded.
    # @param [String] filename Library filename.
    # @note All C extension files are be copied from
    #   <i>EXT_PATH/libraries/stage/PLATFORM + BIT/RUBY_VERSION/</i>.
    # @return [void]
    def add_c_extension(filename)
      filename = File.basename(filename).gsub(/\.(so|bundle)$/, '')
      @c_extensions << filename
    end

    # Add a library file that must be copied/loaded.
    # @param [String] filename Library filename.
    # @note All dll/dylib files are copied from
    #   <i>EXT_PATH/libraries/stage/PLATFORM + BIT/</i>.
    # @return [void]
    def add_required_library(filename)
      filename = File.basename(filename).gsub(/\.(dll|dylib)$/, '')
      @libraries << [filename, true]
    end


    # Add a library file that will be copied/loaded in case it's there.
    # @param [String] filename Library filename.
    # @note All dll/dylib files are copied from
    #   <i>EXT_PATH/libraries/stage/PLATFORM + BIT/</i>.
    # @return [void]
    def add_optional_library(filename)
      filename = File.basename(filename).gsub(/\.(dll|dylib)$/, '')
      @libraries << [filename, false]
    end

    # Add a Ruby file that will be required and ignored from cleanup.
    # @param [String] filename Ruby filename.
    # @note All added rubies are loaded last in the order they are added.
    def add_ruby(filename, only_register = false)
      filename = File.basename(filename).gsub(/\.(rb|rbs|rbe)$/, '')
      @rubies << filename
    end

    # Add a Ruby file that will be ignored from cleanup but not required.
    # @param [String] filename Ruby filename.
    def add_ruby_no_require(filename)
      filename = File.basename(filename).gsub(/\.(rb|rbs|rbe)$/, '')
      @rubies_no_require << filename
    end

    # Copy and load all the required and optional files.
    # @note All .dll files are loaded first, in the order they are added, all
    #   .so or .bundle files afterwards, and all ruby files last. All .dylib
    #   files are expected to be loaded by a C extension.
    # @raise [IOError, LoadError] if a required file doesn't exist.
    # @return [void]
    def require_all
      ops = AMS::IS_PLATFORM_WINDOWS ? 'win' : 'osx'
      bit = AMS::IS_SKETCHUP_64BIT ? '64' : '32'
      rbv = RUBY_VERSION[0..2].to_s
      c_ext = AMS::IS_PLATFORM_WINDOWS ? '.so' : '.bundle'
      l_ext = AMS::IS_PLATFORM_WINDOWS ? '.dll' : '.dylib'

      stage_path = ::File.join(@ext_path, 'libraries', 'stage')
      stage_lib_path = ::File.join(stage_path, ops+bit)
      stage_ext_path = ::File.join(stage_lib_path, rbv)

      version_path = ::File.join(@ext_path, 'libraries', @ext_version)
      version_lib_path = ::File.join(version_path, ops+bit)
      version_ext_path = ::File.join(version_lib_path, rbv)

      temp_version_path = ::File.join(AMS::TEMP_DIR, @ext_name, 'libraries', @ext_version)
      temp_version_lib_path = ::File.join(temp_version_path, ops+bit)
      temp_version_ext_path = ::File.join(temp_version_lib_path, rbv)

      # Check if all the required files exist at version_path.
      load_from_temp = false
      libraries_exist = true
      @libraries.each { |data|
        next unless data[1]
        fpath = ::File.join(version_lib_path, data[0] + l_ext)
        unless ::File.exists?(fpath)
          libraries_exist = false
          break
        end
      }
      if libraries_exist
        @c_extensions.each { |filename|
          fpath = ::File.join(version_ext_path, filename + c_ext)
          unless ::File.exists?(fpath)
            libraries_exist = false
            break
          end
        }
      end
      load_from_temp = false if libraries_exist
      # If not, check if all the required files exist at temp_version_path.
      unless libraries_exist
        libraries_exist = true
        @libraries.each { |data|
          next unless data[1]
          fpath = ::File.join(temp_version_lib_path, data[0] + l_ext)
          if ::File.exists?(fpath)
            libraries_exist = false
            break
          end
        }
        if libraries_exist
          @c_extensions.each { |filename|
            fpath = ::File.join(temp_version_ext_path, filename + c_ext)
            unless ::File.exists?(fpath)
              libraries_exist = false
              break
            end
          }
        end
        load_from_temp = true if libraries_exist
      end
      if !libraries_exist || @experimental
        # If not, first verify that all the required stage files exist.
        unless ::File.directory?(stage_path)
          raise(IOError, "Stage directory, \"#{stage_path}\", is missing!")
        end
        @libraries.each { |data|
          next unless data[1]
          fpath = ::File.join(stage_lib_path, data[0] + l_ext)
          unless ::File.exists?(fpath)
            raise(IOError, "The required, staged library file, \"#{fpath}\", is missing!")
          end
        }
        @c_extensions.each { |filename|
          fpath = ::File.join(stage_ext_path, filename + c_ext)
          unless ::File.exists?(fpath)
            raise(IOError, "The required, staged c extension file, \"#{fpath}\", is missing!")
          end
        }
        # Then, attempt to copy all the stage files to the version_path.
        unless ::File.directory?(stage_path)
          raise(IOError, "Stage directory, \"#{stage_path}\", not found!")
        end
        copying_success = true
        # Create directory to version_ext_path
        unless ::File.directory?(version_ext_path)
          begin
            FileUtils.mkdir_p(version_ext_path)
          rescue Exception => e
            copying_success = false
          end
        end
        if copying_success
          # Then, attempt to copy all the stage files to the version_path.
          @libraries.each { |data|
            fname = data[0] + l_ext
            src_path = ::File.join(stage_lib_path, fname)
            dst_path = ::File.join(version_lib_path, fname)
            # Skip if the file is already copied; or overwrite with a newer version.
            #~ next if ::File.exists?(dst_path)
            # Skip if the file is optional and doesn't exist at stage.
            # If the file is required and doesn't exist at stage,
            # the IOError is raised in code above.
            next if !data[1] && !::File.exists?(src_path)
            # Otherwise copy from stage_lib_path to version_lib_path.
            begin
              FileUtils.copy_file(src_path, dst_path)
            rescue Exception => e
              copying_success = false
              break
            end
          }
        end
        if copying_success
          @c_extensions.each { |filename|
            fname = filename + c_ext
            src_path = ::File.join(stage_ext_path, fname)
            dst_path = ::File.join(version_ext_path, fname)
            # If the file doesn't exist, the IOError is raised in code above.
            # Copy from stage_ext_path to version_ext_path.
            begin
              FileUtils.copy_file(src_path, dst_path)
            rescue Exception => e
              copying_success = false
              break
            end
          }
        end
        if copying_success
          load_from_temp = false
        else
          load_from_temp = true
          # Create directory to temp_version_ext_path
          unless ::File.directory?(temp_version_ext_path)
            FileUtils.mkdir_p(temp_version_ext_path)
          end
          # Otherwise, attempt to copy all the stage files to the temp_version_path.
          # An error in this case will not be handled.
          @libraries.each { |data|
            fname = data[0] + l_ext
            src_path = ::File.join(stage_lib_path, fname)
            dst_path = ::File.join(temp_version_lib_path, fname)
            # Skip if the file is already copied; or overwrite with a newer version.
            #~ next if ::File.exists?(dst_path)
            # Skip if the file is optional and doesn't exist at stage.
            # If the file is required and doesn't exist at stage,
            # the IOError is raised in code above.
            next if !data[1] && !::File.exists?(src_path)
            # Otherwise copy from stage_lib_path to temp_version_lib_path.
            FileUtils.copy_file(src_path, dst_path)
          }
          @c_extensions.each { |filename|
            fname = filename + c_ext
            src_path = ::File.join(stage_ext_path, fname)
            dst_path = ::File.join(temp_version_ext_path, fname)
            # If the file doesn't exist, the IOError is raised in code above.
            # Copy from stage_ext_path to temp_version_ext_path.
            FileUtils.copy_file(src_path, dst_path)
          }
        end
      end
      # Load all in given order, starting from the libraries.
      lib_load_path = load_from_temp ? temp_version_lib_path : version_lib_path
      ext_load_path = load_from_temp ? temp_version_ext_path : version_ext_path
      dll_report = nil
      if !@libraries.empty? && AMS::IS_PLATFORM_WINDOWS
        dll_report = "DLL Report:\n"
        @libraries.each { |data|
          fname = data[0] + l_ext
          fpath = ::File.join(lib_load_path, fname)
          fpath.force_encoding('UTF-8') unless AMS::IS_RUBY_VERSION_18
          if ::File.exists?(fpath)
            dll_report << sprintf("%s : %d\n", fname, AMS::DLL.load_library(fpath))
          else
            dll_report << sprintf("%s : missing\n", fname)
          end
        }
      end
      @c_extensions.each { |filename|
        fname = filename + c_ext
        fpath = ::File.join(ext_load_path, fname)
        if ::File.exists?(fpath)
          begin
            ::Kernel.require(fpath)
          rescue LoadError => e
            msg = "An exception occurred while loading #{@ext_name}, version #{@ext_version}!\n\n#{e.message}"
            msg << "\n\n#{dll_report}" if dll_report
            raise(e.class, msg, caller)
          end
        else
          raise(IOError, "The required c extension file, \"#{fpath}\", is missing!")
        end
      }
      # Require all the rubies.
      @rubies.each { |filename|
        fpath = ::File.join(@ext_path, filename)
        ::Kernel.require(fpath)
      }
    end

    # Erase all unused libraries, c extension files, and unregistered ruby files
    # (if <tt>clean_rubies</tt> is enabled).
    # @note This does not erase any files from the TEMP folder, as they may be
    #   used by other SketchUp versions.
    # @note This does not raise any errors upon failure to delete a file or a
    #   directory.
    # @param [Boolean] clean_rubies Whether to delete all unregistered Ruby
    #   files within <i>EXT_PATH</i>.
    # @return [void]
    def clean_up(clean_rubies = false)
      lib_load_dir = ::File.join(@ext_path, 'libraries')
      lib_load_dir.force_encoding("UTF-8") unless AMS::IS_RUBY_VERSION_18
      if ::File.directory?(lib_load_dir)
        to_skip = ['.', '..', 'stage', @ext_version]
        ::Dir.entries(lib_load_dir).each { |entry|
          next if to_skip.include?(entry)
          entry_fpath = ::File.join(lib_load_dir, entry)
          entry_fpath.force_encoding("UTF-8") unless AMS::IS_RUBY_VERSION_18
          begin
            FileUtils.rm_r(entry_fpath)
          rescue Exception => e
            # Do nothing
          end
        }
      end
      if clean_rubies
        ::Dir.glob( ::File.join(@ext_path, '*.{rb, rbs, rbe}') ).each { |fpath|
          fpath.force_encoding("UTF-8") unless AMS::IS_RUBY_VERSION_18
          basename = ::File.basename(fpath, '.*')
          next if @rubies.include?(basename) || @rubies_no_require.include?(basename)
          begin
            ::File.delete(fpath)
          rescue Exception => e
            # Do nothing
          end
        }
      end
    end

  end # class ExtensionManager
end # module AMS
