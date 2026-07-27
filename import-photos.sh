#!/bin/bash
#
# import-photos.sh
#
# Copies RAW photo files from an SD card or tethered camera volume into
# a photo library, sorted by capture date into a Lightroom-friendly
# <year>/<YYYY-MM-DD>/ folder structure.
#
# Originals on the card/camera are left untouched (copy, not move).
# Files that already exist at the destination are skipped, so it's
# always safe to re-run against the same card.
#
# Usage:
#   ./import-photos.sh /Volumes/NO_NAME
#   ./import-photos.sh "/Volumes/Leica Q3"
#   DEST_BASE="/Volumes/media/Photography" ./import-photos.sh /Volumes/NO_NAME
#
# Configuration (all optional, set via environment variables):
#   DEST_BASE   Destination library root. Default: ./Photography
#   EXTENSIONS  Space-separated list of extensions to import.
#               Default: "RAF DNG CR2 CR3 NEF ARW ORF"
#
# Requires: exiftool (brew install exiftool / apt install libimage-exiftool-perl)
#
# MIT License — see LICENSE file.

set -uo pipefail

SOURCE="${1:-}"
DEST_BASE="${DEST_BASE:-./Photography}"
EXTENSIONS="${EXTENSIONS:-RAF DNG CR2 CR3 NEF ARW ORF}"

# --- Sanity checks -----------------------------------------------------

if [ -z "$SOURCE" ]; then
  echo "Usage: $0 /path/to/sd-card-or-camera-volume"
  echo ""
  echo "Optional environment variables:"
  echo "  DEST_BASE   Destination library root (default: ./Photography)"
  echo "  EXTENSIONS  File extensions to import (default: RAF DNG CR2 CR3 NEF ARW ORF)"
  echo ""
  echo "Currently mounted volumes:"
  ls /Volumes/ 2>/dev/null || echo "  (none found — are you on macOS?)"
  exit 1
fi

if ! command -v exiftool >/dev/null 2>&1; then
  echo "Error: exiftool not found."
  echo "  macOS:  brew install exiftool"
  echo "  Linux:  sudo apt install libimage-exiftool-perl"
  exit 1
fi

if [ ! -d "$SOURCE" ]; then
  echo "Error: source path '$SOURCE' not found."
  echo "Currently mounted volumes:"
  ls /Volumes/ 2>/dev/null
  exit 1
fi

if [ ! -d "$DEST_BASE" ]; then
  echo "Error: destination '$DEST_BASE' not found."
  echo "Create it first, or point DEST_BASE at an existing library root."
  exit 1
fi

# --- Build file list -----------------------------------------------------

# Build the find(1) expression dynamically from EXTENSIONS
FIND_ARGS=()
for EXT in $EXTENSIONS; do
  if [ ${#FIND_ARGS[@]} -gt 0 ]; then
    FIND_ARGS+=(-o)
  fi
  FIND_ARGS+=(-iname "*.${EXT}")
done

echo "Scanning $SOURCE for: $EXTENSIONS ..."

TMP_LIST=$(mktemp)
trap 'rm -f "$TMP_LIST"' EXIT

find "$SOURCE" -type f \( "${FIND_ARGS[@]}" \) > "$TMP_LIST"

TOTAL=$(wc -l < "$TMP_LIST" | tr -d ' ')

if [ "$TOTAL" -eq 0 ]; then
  echo "No matching RAW files found in $SOURCE."
  exit 0
fi

echo "Found $TOTAL file(s). Sorting by capture date into $DEST_BASE ..."
echo ""

# --- Copy loop (fed via process substitution so counters survive the loop) -

COPIED=0
SKIPPED=0
FAILED=0

while IFS= read -r FILE; do
  DATE=$(exiftool -DateTimeOriginal -d "%Y-%m-%d" -s -s -s "$FILE" 2>/dev/null)

  if [ -z "$DATE" ]; then
    echo "  WARNING: no capture date found for $(basename "$FILE"), skipping."
    FAILED=$((FAILED + 1))
    continue
  fi

  YEAR="${DATE:0:4}"
  DEST_DIR="$DEST_BASE/$YEAR/$DATE"
  DEST_FILE="$DEST_DIR/$(basename "$FILE")"

  if [ -f "$DEST_FILE" ]; then
    echo "  Skipped (already exists): $(basename "$FILE")  [$YEAR/$DATE]"
    SKIPPED=$((SKIPPED + 1))
    continue
  fi

  mkdir -p "$DEST_DIR"
  cp -p "$FILE" "$DEST_FILE"

  if [ $? -eq 0 ]; then
    echo "  Copied: $(basename "$FILE")  ->  $YEAR/$DATE/"
    COPIED=$((COPIED + 1))
  else
    echo "  FAILED to copy: $(basename "$FILE")"
    FAILED=$((FAILED + 1))
  fi

done < "$TMP_LIST"

# --- Summary -------------------------------------------------------------

echo ""
echo "-------------------------------------"
echo "Import complete."
echo "  Copied:  $COPIED"
echo "  Skipped: $SKIPPED (already existed at destination)"
echo "  Failed:  $FAILED (no EXIF date or copy error)"
echo "-------------------------------------"
echo ""
echo "Originals on $SOURCE were left untouched."
echo "Next step: in Lightroom, use File > Add Photos to Catalog and point at the new date folder(s) above."
