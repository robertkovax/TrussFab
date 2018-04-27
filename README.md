# TrussMech

SketchUp plug-in to create large-scale 3D-printed truss structures by using ready-made objects (e.g. PET bottles) and linear actuators.

## Installation

### SketchUp Plugin

Find your [Sketchup Plugin directory](http://www.sketchup.com/intl/en/developer/docs/loading), it is usually located at:
- Windows: `C:\Users\me\AppData\Roaming\SketchUp\SketchUp 2017\SketchUp\Plugins`
- macOS: `/Users/me/Library/Application Support/SketchUp 2017/SketchUp/Plugins`.

In that plugin directory, create a Ruby file called `truss_fab_plugin.rb` with the content:

```ruby
$LOAD_PATH << "PATH_TO_TRUSSFAB" # replace with directory of this repository
require 'truss_fab.rb'

SKETCHUP_CONSOLE.show # shows Ruby console in SketchUp
TrussFab.start # starts the plugin
```

Restart SketchUp for the changes to take effect. If it works will you see an extra window in SketchUp with the title 'TrussFab'.

### Force analysis server

* To run the force analysis server, you need Rhino, Grasshopper, Karamba, and Python 2 installed.

* We set it up on the HPI machine fb07mpbpws2015 which can be accessed via Windows Remote Desktop.

* In a run-as-administrator command line in `bottleProject/fea_server/`, run `python feaServerService.py install`, `python feaServerService.py start` and `python feaServerService.py stop` to change the state of the service.

* It will also continue running after you log off.

* Once installed, it can also be started/stopped from the Windows Services GUI under the name "Fea Server".

* To kill it if unresponsive, run `sc queryex "Fea Server"` which will print the PID, say 3582, then run `taskkill /F /PID 3582`


## Usage

[TBD: Add toolbar image]

**DO NOT USE `CTRL + Z`**. This will ruin the internal data structure. Also, do not use the standard Sketchup tools for manipulating the model (move, rotate, ...).

### Drawing Individual Links

Select the draw tool from the BottlePrint toolbar and click on the ground to start drawing a link. Move your mouse and click again to finish placing it. If the bottle layer is active, you should now see a bottle.

Note that once there are links in the model, the draw tool will help you by snapping to hubs.

### Drawing Multiple Links

Use the Tetrahedron and Octahedron tools from the toolbar to place multiple links. Click the ground or the triangle surface of an already-drawn tetrahedron/octahedron to place another.

### Deleting Links

Select the delete tool from the toolbar. Click on links, hubs, pods or covers to delete them.

### Layers

From the SketchUp menu bar, select `Windows`, `Layer` to show the Layer panel. Use its checkboxes to control what you see.

[TBD add Layer image]

### Additional tools

[TBD]

## Export Hubs for Print

To generate .scad files from Sketchup

1. Click "Fabricate!"
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

* The source code is in the /src/ folder.

* Every button from the /src/ui/ has one tool in the /src/tools/ folder.

* Tools are used for getting user input, the actual logic should happen in /src/utility.

* The graph and graph objects in /src/database/ control the logic of the data structure, regarding positions, transformations, creation, deletion, storing and highlighting

* The thingies in /src/thingies/ control the SketchUp objects belonging to graph objects. They don't implement logic other than creation, deletion, transformation and material changing of the Sketchup Entities.

* /src/models/ manages Sketchup ComponentDefinitions created from .skp files. These can be instantiated to Sketchup ComponentInstances with a transformation to put them in the right place.

### Concerning the SketchUp API

* [Sketchup Ruby API](http://www.sketchup.com/intl/en/developer/index), [Tutorials](http://www.sketchup.com/intl/en/developer/docs/tutorial_geometry)

* Be careful with SketchUp observers. We had bad experiences.

* Prevent automated geometry merging: In Sketchup, if two entities (e.g. edges) are exactly on the same position, they are merged. The whole model is simplified constantly. To prevent that, use groups to wrap the entites.

* Sketchup does not support multi threading in it's plugins.

### Debugger

After downloading the dll from the releases of https://github.com/SketchUp/sketchup-ruby-debugger and copying it to SketchUp Installation folder, starting SketchUp with the argument `SketchUp.exe -rdebug "ide port=1234"` lets you connect a debugger like RubyMine’s. SketchUp will start up and block with a white screen until the debugger is connected.

Also, use SketchUp’s Ruby Console to try for example `Graph.instance.empty?`.

### Creating new Bottle Models

[TBD]

### Dev Commands

The ruby console in Sketchup can be used to interact with the TrussFab Plugin.
Available commands are:
    TrussFab.reload - reloads ruby and js files for faster development (do this after you changed code you want to test)
    TrussFab.store_sensor_output - toggles writing the output of the sensors into a .csv-style file, which will be located in the home folder (called sensor_output.log)

# Contact handles

robert.kovacs@hpi.de

anna.seufert@student.hpi.de

ludwig.wall@student.hpi.de
