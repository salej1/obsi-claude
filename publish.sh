#!/bin/bash

if [ $# -eq 0 ]; then
    echo "Usage: $0 <destination_path>"
    echo "Example: $0 /path/to/destination"
    exit 1
fi

DEST_PATH="$1"

if [ ! -d "$DEST_PATH" ]; then
    echo "Error: Destination path '$DEST_PATH' does not exist"
    exit 1
fi

if [ ! -d "config" ]; then
    echo "Error: 'config' folder not found in current directory"
    exit 1
fi

if [ ! -d "templater" ]; then
    echo "Error: 'templater' folder not found in current directory"
    exit 1
fi

echo "Copying folders to $DEST_PATH..."

cp -r config "$DEST_PATH/"
if [ $? -eq 0 ]; then
    echo "✓ config folder copied successfully"
else
    echo "✗ Failed to copy config folder"
    exit 1
fi

cp -r templater "$DEST_PATH/"
if [ $? -eq 0 ]; then
    echo "✓ templater folder copied successfully"
else
    echo "✗ Failed to copy templater folder"
    exit 1
fi

echo "All folders copied successfully to $DEST_PATH"