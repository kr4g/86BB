#!/bin/bash
set -e

SAMPLES_DIR="$(cd "$(dirname "$0")/.." && pwd)/av-engine/samples"
mkdir -p "$SAMPLES_DIR"

REPO="kr4g/86BB"
TAG="v0.1-assets"

FILES=(
    "gut_recording.wav"
)

for file in "${FILES[@]}"; do
    if [ ! -f "$SAMPLES_DIR/$file" ]; then
        echo "Downloading $file..."
        curl -L "https://github.com/$REPO/releases/download/$TAG/$file" -o "$SAMPLES_DIR/$file"
        echo "Done."
    else
        echo "$file already exists, skipping."
    fi
done
