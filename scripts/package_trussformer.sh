#! /bin/bash
echo "This script has to be called from TrussFormer's root directory!"
mkdir TrussFormer

cp -r lib/ TrussFormer/lib/
cp -r src/ TrussFormer/src/
cp -r scripts/ TrussFormer/scripts/
cp -r assets/ TrussFormer/assets/
rm -r TrussFormer/assets/exports
cp -r bin/ TrussFormer/bin/
cp truss_fab.rb TrussFormer/
cp reloader.rb TrussFormer/
cp Bottle\ Editor\ Style1.style TrussFormer/

zip -r TrussFormer.rbz TrussFormer/ TrussFormer.rb

rm -rf TrussFormer
