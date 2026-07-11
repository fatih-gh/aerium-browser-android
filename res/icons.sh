#!/bin/sh

# Renders the Aerium logo over an existing icon PNG, keeping its dimensions.
# Usage: icons.sh <path-to-png>
svg=$(dirname "$0")/aerium.svg
w=$(identify -format %w "$1")

case $(basename "$1") in
  layered_app_icon_background*)
    # Adaptive icon background layer: solid white full bleed
    convert -size ${w}x${w} xc:'#ffffff' "$1" ;;
  layered_app_icon*)
    # Legacy layered icon: white background with the logo at 66% (safe zone)
    fg=$((w * 66 / 100))
    rsvg-convert -w $fg -h $fg "$svg" -o "$1.fg.png"
    convert -size ${w}x${w} xc:'#ffffff' "$1.fg.png" -gravity center -composite "$1"
    rm -f "$1.fg.png" ;;
  *)
    # Plain app icon: full-size logo (circular artwork masks well)
    rsvg-convert -w "$w" -h "$w" "$svg" -o "$1" ;;
esac
echo "aerium icon: $1 (${w}px)"
