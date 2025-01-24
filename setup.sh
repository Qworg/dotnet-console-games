#!/bin/bash

# Find all .csproj files in the repository and print their full paths
find . -type f -name "*.csproj" -exec readlink -f {} \;
