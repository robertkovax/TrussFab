#!/bin/bash

for i in *.scad
do
    echo "Rendering the file $i"
    openscad -o ${i%.*}.stl $i
    echo Done
done
