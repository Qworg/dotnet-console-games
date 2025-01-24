#!/bin/bash

cd $dir
# Attempt to build the .NET project
dotnet build
if [ $? -eq 0 ]; then
    # Find first json in temp_folder and copy it to currentchunk.json
    SOURCE_JSON=$(find "$temp_folder" -maxdepth 1 -type f -name '*.json' -print -quit)
    if [ -n "$SOURCE_JSON" ]; then
        cp -v "$SOURCE_JSON" currentchunk.json
    else
        echo "Error: No .json found in temp_folder"
        exit 1
    fi
else
    echo "Error: Dotnet build failed"
    exit 1
fi
