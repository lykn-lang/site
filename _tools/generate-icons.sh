#!/bin/sh
# Regenerate with ImageMagick: sh _tools/generate-icons.sh /path/to/Avatar-x500-rounded.png
# The underscore directory keeps this tool out of Cobalt's published output.
set -eu

if [ "$#" -ne 1 ] || [ ! -f "$1" ]; then
    echo "Usage: sh _tools/generate-icons.sh SOURCE.png" >&2
    exit 1
fi

source_image=$1
site_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
icon_background='#1a2b1f'

# Preserve the supplied rounded corners for browser favicons.
for size in 16 32 48 96; do
    magick "$source_image" -filter Lanczos -resize "${size}x${size}" -strip \
        "$site_dir/favicon-${size}x${size}.png"
done
magick "$site_dir/favicon-16x16.png" "$site_dir/favicon-32x32.png" \
    "$site_dir/favicon-48x48.png" "$site_dir/favicon.ico"

# Apple and Android's maskable icons need an opaque canvas; the OS supplies the mask.
for size in 120 152 167 180; do
    icon_file="apple-touch-icon-${size}x${size}.png"
    if [ "$size" = 180 ]; then icon_file='apple-touch-icon.png'; fi
    magick "$source_image" -background "$icon_background" -alpha remove -alpha off \
        -filter Lanczos -resize "${size}x${size}" -strip "$site_dir/$icon_file"
done

for size in 192 512; do
    magick "$source_image" -filter Lanczos -resize "${size}x${size}" -strip \
        "$site_dir/android-chrome-${size}x${size}.png"
done

# Full-bleed artwork: its central lichen/orange detail remains inside the mask safe area.
magick "$source_image" -background "$icon_background" -alpha remove -alpha off \
    -filter Lanczos -resize 512x512 -strip "$site_dir/android-chrome-maskable-512x512.png"
