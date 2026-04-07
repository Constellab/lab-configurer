#!/bin/bash

# Get the directory where the script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

# Get the parent directory (lab-configurer root)
ROOT_DIR="$(dirname "$SCRIPT_DIR")"

# Call the prepare_server.sh script
echo "Preparing server environment..."
bash "${ROOT_DIR}/utils/prepare_server.sh"

# Create web shortcuts
echo "Creating web shortcuts..."

# Create Lab Manager shortcut
bash "${SCRIPT_DIR}/create-web-shortcut.sh" --url "http://localhost:82" --name "Lab Manager"

# Create Lab shortcut
bash "${SCRIPT_DIR}/create-web-shortcut.sh" --url "http://localhost:89" --name "Lab"

echo "Desktop initialization complete!"

# Prompt user to confirm reboot instead of automatic reboot
echo "A system reboot is required to complete the setup."
if zenity --question --title="System Reboot Required" --text="Setup is complete. The system needs to reboot now.\n\nDo you want to reboot now?" --ok-label="Reboot Now" --cancel-label="Later"; then
    echo "Rebooting system now..."
    reboot
else
    echo "Reboot cancelled. Please remember to reboot your system later."
fi

