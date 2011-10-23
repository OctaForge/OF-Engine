#!/bin/sh
if [ -d "~/output" ]; then # If the dir output exists..
naturaldocs -i ../data -p . -o HTML output -s # Then create doc
else 
mkdir output # Else, create directory
naturaldocs -i ../data -p . -o HTML output -s # And then create doc.
fi
