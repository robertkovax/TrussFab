To load your own bottle models, follow these rules:

The specification for the bottle model is coded in the filename (.skp)

The specification has the elements: 
number - Only used for sorting, the first bottle will be the 'default' bottle
name - Used to describe the connection
short_name - Used short to describe the connection, this will be used for example in the connection count tool
weight - The weight of the link in grams 

And the following format:
'number-name-short_name-weight.skp'

Example:
'2-single bottle-single-1000.skp' (This bottle's name would be 'single bottle', short_name: 'single', and have a weight of 1000grams)

The 3D-File will be loaded, but the materials in the file will partly be overwritten for the trussfab color scheme. Try to create a Sketchup file with no material in it, as it will take more time to load the file. 
The length of the connection will be the length of the model on the z-Axis.
For best results, try to place the models bottom center in the origin of the coordinate system, and then the connection up on the z-Axis, centered around the z-Axis. For an example file just open the models in this folder.