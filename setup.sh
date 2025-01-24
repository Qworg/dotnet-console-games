#!/bin/bash

# Find all .csproj files in the repository and run upgrade analysis
find . -type f -name "*.csproj" -print0 | while IFS= read -r -d '' csproj; do
    dir=$(readlink -f "$(dirname "$csproj")")
    echo "Analyzing $dir"
    upgrade-assistant analyze --non-interactive \
        --source "$(readlink -f "$csproj")" \
        -f net9.0 \
        -r "$dir/report.json" \
        --serializer JSON \
        --code \
        --binaries \
        --privacyMode Unrestricted
done
