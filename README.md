# Bottle Project

SketchUp plug-in to create large-scale 3D-printed objects by using ready-made objects (e.g. PET bottles).

## Installation

### SketchUp Plugin

Find your [Sketchup Plugin directory](http://www.sketchup.com/intl/en/developer/docs/loading), it is usually located at:
- Windows: `C:\Users\me\AppData\Roaming\SketchUp\SketchUp 2017\SketchUp\Plugins`
- macOS: `/Users/me/Library/Application Support/SketchUp 2017/SketchUp/Plugins`.

In that plugin directory, create a Ruby file called `ex_truss_fab.rb` with the content:

```ruby
$LOAD_PATH << "PATH_TO_TRUSSFAB"
require 'truss_fab.rb'

Sketchup.send_action(CMD_RUBY_CONSOLE)
TrussFab.start
```

(In the first line, replace the load path with the directory of your `trussFab` directory.)

Additionally install the following two libraries into the plugin directory by copying the contents of the 'lib' directory into it:

* [httparty v0.13.7](https://github.com/jnunemaker/httparty/releases)
* [multi_xml v0.5.5](https://github.com/sferik/multi_xml/releases)

The plugin directory should now look like this:
* bottleProject.rb (the file you created)
* httparty/
* httparty.rb
* multi_xml/
* multi_xml.rb

Restart SketchUp for the changes to take effect. If it works will you see an extra window in SketchUp with the title 'TrussFab'.

### Force analysis server

* To run the force analysis server, you need Rhino, Grasshopper, Karamba, and Python 2 installed.

* We set it up on the HPI machine fb07mpbpws2015 which can be accessed via Windows Remote Desktop.

* In a run-as-administrator command line in `bottleProject/fea_server/`, run `python feaServerService.py install`, `python feaServerService.py start` and `python feaServerService.py stop` to change the state of the service.

* It will also continue running after you log off.

* Once installed, it can also be started/stopped from the Windows Services GUI under the name "Fea Server".

* To kill it if unresponsive, run `sc queryex "Fea Server"` which will print the PID, say 3582, then run `taskkill /F /PID 3582`


## Usage

Open SketchUp and in the menu bar select `Extensions`, `Activate BottleProject`. The BottlePrint toolbar should come up:

![Toolbar](/readme_images/toolbar.png?raw=true "Toolbar")

(If it doesn’t show, it might be hidden. Try right-clicking in the toolbar area and pick `Bottle Project`.)

Another window offers additional functionality:

![Additional Functionalities](/readme_images/ui.png?raw=true "GUI")

**DO NOT USE `CTRL + Z`**. This will ruin the internal data structure. Also, do not use the standard Sketchup tools for manipulating the model (move, rotate, ...).

### Drawing Individual Links

Select the draw tool from the BottlePrint toolbar and click on the ground to start drawing a link. Move your mouse and click again to finish placing it. If the bottle layer is active, you should now see a bottle.

Note that once there are links in the model, the draw tool will help you by snapping to hubs.

Activate fixed-angle construction lines in the UI window to guide your drawing.

### Drawing Multiple Links

Use the Tetrahedron and Octahedron draw tools from the toolbar to place multiple links. Click the ground or the triangle surface of an already-drawn tetrahedron/octahedron to place another.

### Deleting Links

With the select tool from the toolbar, select hubs or links, then press D to delete them. Do **not** press the Delete key.

Deleting hubs will also delete adjacent Links. Hold down shift to select multiple hubs.

### Layers

From the SketchUp menu bar, select `Windows`, `Layer` to show the Layer panel. Use its checkboxes to control what you see.

![Layers](/readme_images/layers.png?raw=true "Layers")

## Export Hubs for Print

To generate .scad files from Sketchup

1. Click "Export Hubs"
2. Select the folder in which to save the .scad files. (Recommended: ./openscad/files/%ProjectName%)

To Generate .stl files:

1. Open generated .scad file
2. adjust the path to the LibSTLExport.scad file if neccessary
3. Save and click Render (F6)
4. Click Export as STL

## Printing

Print Steps:

0. Setup Simplify3D profile to match your printer!

1. Open .stl file in Simplify3D. (File->Import Models)
2. Select/add matching printer process
3. Double click the object
	3.a) Adjust the position and orientation
4. Click "Prepare to Print!"
5. Click "Save Toolpaths to Disk"
	5.a) Save files on SD-card
6. Insert SD-Card into Makerbot
7. Select the File to print (check if there is enough material)



## Development

Entry points are bp_toolbar.rb and the tools created there.

### Concerning the SketchUp API

* [Sketchup Ruby API](http://www.sketchup.com/intl/en/developer/index), [Tutorials](http://www.sketchup.com/intl/en/developer/docs/tutorial_geometry)

* Be careful with SketchUp observers. We had bad experiences.

* Prevent automated geometry merging: In Sketchup, if two entities (e.g. edges) are exactly on the same position, they are merged. The whole model is simplified constantly. To prevent that, use groups to wrap the entites.

### Debugger

After downloading the dll from the releases of https://github.com/SketchUp/sketchup-ruby-debugger and copying it to SketchUp Installation folder, starting SketchUp with the argument `SketchUp.exe -rdebug "ide port=1234"` lets you connect a debugger like RubyMine’s. SketchUp will start up and block with a white screen until the debugger is connected.

Also, use SketchUp’s Ruby Console to try for example `Storage.instance.combined_links`.

### Creating new Bottle Models

The bottle models in `models/initComponents/` were created using the `double_bottle_factory.rb` script, which is not loaded as part of the program.
Start SketchUp, require the file from the rubyConsole and call its functions. Remember do delete everything else from the model and clean up unused definitions. Then save it as an skp file in the right directory.

# Contact handles

robert.kovacs@hpi.de
anna.seufert@student.hpi.de
ludwig.wall@student.hpi.de
