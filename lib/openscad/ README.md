# OpenScad

In order to create the connectors, we use [OpenScad](http://www.openscad.org/) to generate the files for the 3d printer. To get started, check out the [manual](https://en.wikibooks.org/wiki/OpenSCAD_User_Manual).

Generall Printing Workflow:

1.  model in the editor
2.  export to OpenScad files
3.  review OpenScad files and export to STL files
4.  print with STL files

There exists two different 'waves' of OpenScad files within the projects. A lot of work was done before the kinematics features. The folder `ConnectorTypes`, `Models`, `Modes` belong to the first wave. The second wave is about the kinematics which is in `Kinematics`.

In general, it's hard to understand what's going on in those files. If you need to extend something, it may be better to start from scratch.
