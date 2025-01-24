#!/bin/bash

# Attempt to build the .NET project
dotnet build
if [ $? -eq 0 ]; then
    # Find first chunk.json in temp_folder and copy it
    SOURCE_JSON=$(find temp_folder -maxdepth 1 -type f -name 'chunk.json' -print -quit)
    if [ -n "$SOURCE_JSON" ]; then
        cp -v "$SOURCE_JSON" chunk.json
    else
        echo "Error: No chunk.json found in temp_folder"
        exit 1
    fi
else
    echo "Error: Dotnet build failed"
    exit 1
fi
