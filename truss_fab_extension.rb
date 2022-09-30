require 'sketchup.rb'
require 'extensions.rb'


NAME         = 'TrussFab'.freeze
VERSION      = '1.0.0'.freeze
RELEASE_DATE = 'July 19, 2017'.freeze

# Create the extension.
@extension = ::SketchupExtension.new(NAME, 'TrussFab/start_truss_fab.rb')

# Attach some nice info.
@extension.description = "bottles bottles bottles :-)"
@extension.version     = VERSION
@extension.copyright   = 'HPI © 2017'
@extension.creator     = 'Róbert Kovács (robert.kovacs@hpi.de)'

# Register and load the extension on start-up.
::Sketchup.register_extension(@extension, true)