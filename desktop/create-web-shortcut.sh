#!/bin/bash

# Script to create a website shortcut on Ubuntu desktop
# Author: GitHub Copilot

# Function to display help
show_help() {
  echo "Usage: create-web-shortcut [OPTIONS]"
  echo ""
  echo "Options:"
  echo "  --url, -u URL      The website URL (e.g., https://example.com)"
  echo "  --name, -n NAME    The name for the shortcut"
  echo "  --icon, -i PATH    Path to an icon file (optional)"
  echo "  --help, -h         Show this help message"
  echo ""
  echo "If no options are provided, the script will run in interactive mode."
}

# Process command-line arguments
website_url=""
shortcut_name=""
icon_path=""

# Check if we have any arguments
if [ $# -eq 0 ]; then
  # Interactive mode
  echo "Website Shortcut Creator for Ubuntu"
  echo "--------------------------------"
  read -p "Enter website URL (e.g., https://example.com): " website_url
  read -p "Enter shortcut name: " shortcut_name
  read -p "Enter icon path (optional, press Enter to skip): " icon_path
else
  # Parse command-line arguments
  while [ $# -gt 0 ]; do
    case "$1" in
      --url|-u)
        website_url="$2"
        shift 2
        ;;
      --name|-n)
        shortcut_name="$2"
        shift 2
        ;;
      --icon|-i)
        icon_path="$2"
        shift 2
        ;;
      --help|-h)
        show_help
        exit 0
        ;;
      *)
        echo "Error: Unknown option $1"
        show_help
        exit 1
        ;;
    esac
  done
fi

# Validate required inputs
if [ -z "$website_url" ]; then
  echo "Error: Website URL is required."
  show_help
  exit 1
fi

if [ -z "$shortcut_name" ]; then
  echo "Error: Shortcut name is required."
  show_help
  exit 1
fi

# Validate URL
if [[ ! $website_url =~ ^https?:// ]]; then
  echo "Warning: URL should start with http:// or https://. Adding https:// prefix."
  website_url="https://$website_url"
fi

# Find default browser icon
default_icon=""
# Common browser icon locations
possible_icons=(
  "/usr/share/icons/hicolor/scalable/apps/firefox.svg"
  "/usr/share/icons/hicolor/128x128/apps/firefox.png"
  "/usr/share/icons/hicolor/scalable/apps/chromium.svg"
  "/usr/share/icons/hicolor/128x128/apps/chromium.png"
  "/usr/share/icons/hicolor/scalable/apps/google-chrome.svg"
  "/usr/share/icons/hicolor/128x128/apps/google-chrome.png"
  "/usr/share/icons/hicolor/scalable/apps/web-browser.svg"
  "/usr/share/icons/hicolor/128x128/apps/web-browser.png"
  "/usr/share/icons/gnome/48x48/categories/applications-internet.png"
)

for icon in "${possible_icons[@]}"; do
  if [ -f "$icon" ]; then
    default_icon="$icon"
    break
  fi
done

# Create desktop file content
desktop_content="[Desktop Entry]
Version=1.0
Type=Application
Name=$shortcut_name
Comment=Web shortcut for $shortcut_name
Exec=xdg-open $website_url
Terminal=false
Categories=Network;WebBrowser;"

# Add icon if provided or use default
if [ -n "$icon_path" ] && [ -f "$icon_path" ]; then
  desktop_content+="
Icon=$icon_path"
  echo "Using custom icon: $icon_path"
elif [ -n "$default_icon" ]; then
  desktop_content+="
Icon=$default_icon"
  echo "Using default browser icon: $default_icon"
else
  echo "No suitable icon found. Shortcut will use system default."
fi

# Check if Desktop directory exists
if [ -d "$HOME/Desktop" ]; then
  desktop_dir="$HOME/Desktop"
elif [ -d "$HOME/Bureau" ]; then  # French localization sometimes uses "Bureau"
  desktop_dir="$HOME/Bureau"
else
  echo "Desktop directory not found. Creating shortcut in home directory instead."
  desktop_dir="$HOME"
fi

# Create the desktop file
desktop_file="$desktop_dir/${shortcut_name// /_}.desktop"
echo "$desktop_content" > "$desktop_file"

# Check if file was created successfully
if [ -f "$desktop_file" ]; then
  # Make the file executable with both chmod commands to ensure it works
  chmod +x "$desktop_file"
  chmod 755 "$desktop_file"
  
  # Try to set executable bit using gio if available (for newer Ubuntu versions)
  if command -v gio &> /dev/null; then
    gio set "$desktop_file" "metadata::trusted" true
    echo "Set trusted metadata using gio."
  fi
  
  echo "Making shortcut executable..."
  echo "Shortcut created successfully at: $desktop_file"
  echo ""
  echo "If the shortcut doesn't work immediately, try these steps:"
  echo "1. Right-click the file and select 'Properties'"
  echo "2. Go to the 'Permissions' tab"
  echo "3. Check the box for 'Allow executing file as program'"
  echo "4. Or run this command: chmod +x '$desktop_file'"
else
  echo "Error: Failed to create shortcut at $desktop_file."
  exit 1
fi

exit 0
