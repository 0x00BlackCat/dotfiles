#!/bin/bash

set -e

WALLPAPER_DIR="$HOME/Pictures/Wallpapers"

if [ ! -d "$WALLPAPER_DIR" ]; then
    echo "ERROR: Wallpaper directory '$WALLPAPER_DIR' does not exist"
    exit 1
fi

if ! command -v swww >/dev/null 2>&1; then
    echo "ERROR: swww is not installed"
    exit 1
fi

if ! command -v wofi >/dev/null 2>&1; then
    echo "ERROR: wofi is not installed"
    exit 1
fi

# Find all image files in the wallpaper directory
wallpapers=()
while IFS= read -r -d '' file; do
    wallpapers+=("$file")
done < <(find "$WALLPAPER_DIR" -type f \( \
    -iname "*.jpg" -o \
    -iname "*.jpeg" -o \
    -iname "*.png" -o \
    -iname "*.webp" -o \
    -iname "*.bmp" -o \
    -iname "*.gif" \
\) -print0 | sort -z)

if [ ${#wallpapers[@]} -eq 0 ]; then
    echo "ERROR: No wallpapers found in $WALLPAPER_DIR"
    exit 1
fi

display_names=()
for wallpaper in "${wallpapers[@]}"; do
    display_names+=("$(basename "$wallpaper")")
done

selected=$(printf '%s\n' "${display_names[@]}" | wofi --dmenu --prompt "Select Wallpaper")

if [ -z "$selected" ]; then
    exit 0
fi

selected_path=""
for wallpaper in "${wallpapers[@]}"; do
    if [ "$(basename "$wallpaper")" = "$selected" ]; then
        selected_path="$wallpaper"
        break
    fi
done

if [ -z "$selected_path" ]; then
    echo "ERROR: Could not find selected wallpaper"
    exit 1
fi

# Set the wallpaper
swww img "$selected_path" --transition-type any --transition-fps 180

echo "Wallpaper set to: $selected"

if command -v notify-send >/dev/null 2>&1; then
    notify-send "Wallpaper Changed" "$selected"
fi

