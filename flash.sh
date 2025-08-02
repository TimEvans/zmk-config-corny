#!/bin/bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FIRMWARE_DIR="$SCRIPT_DIR/firmware-builds"

show_usage() {
    echo "Usage: $0 <left|right>"
    echo "Flash ZMK firmware to Corne keyboard"
    echo ""
    echo "Arguments:"
    echo "  left   Flash left side firmware"
    echo "  right  Flash right side firmware"
    exit 1
}

find_nicenano_devices() {
    local devices=()
    
    # Check common mount points
    for mount_point in "/run/media/$USER/NICENANO" "/media/$USER/NICENANO" "/mnt/NICENANO"; do
        if [[ -d "$mount_point" ]]; then
            devices+=("$mount_point")
        fi
    done
    
    # Search for NICENANO in all mount points
    while IFS= read -r -d '' device; do
        if [[ "$device" == *"NICENANO"* ]]; then
            devices+=("$device")
        fi
    done < <(find /run/media /media /mnt 2>/dev/null -maxdepth 3 -name "*NICENANO*" -type d -print0 2>/dev/null || true)
    
    # Remove duplicates
    printf '%s\n' "${devices[@]}" | sort -u
}

select_device() {
    local devices
    mapfile -t devices < <(find_nicenano_devices)
    
    if [[ ${#devices[@]} -eq 0 ]]; then
        echo "No NICENANO devices found." >&2
        echo "Please ensure your keyboard is:" >&2
        echo "1. Connected via USB" >&2
        echo "2. In bootloader mode (double-tap reset button)" >&2
        echo "3. Properly mounted" >&2
        exit 1
    elif [[ ${#devices[@]} -eq 1 ]]; then
        echo "Found NICENANO device: ${devices[0]}" >&2
        echo "${devices[0]}"
    else
        echo "Multiple NICENANO devices found:" >&2
        for i in "${!devices[@]}"; do
            echo "$((i+1)). ${devices[i]}" >&2
        done
        
        while true; do
            read -p "Select device (1-${#devices[@]}): " choice >&2
            if [[ "$choice" =~ ^[0-9]+$ ]] && [[ "$choice" -ge 1 ]] && [[ "$choice" -le ${#devices[@]} ]]; then
                echo "${devices[$((choice-1))]}"
                break
            else
                echo "Invalid selection. Please choose a number between 1 and ${#devices[@]}." >&2
            fi
        done
    fi
}

flash_firmware() {
    local side="$1"
    local firmware_file="$FIRMWARE_DIR/corne_${side}-nice_nano_v2-zmk.uf2"
    
    # Check if firmware file exists
    if [[ ! -f "$firmware_file" ]]; then
        echo "Error: Firmware file not found: $firmware_file"
        echo "Please ensure the firmware has been built and is available in the firmware-builds directory."
        exit 1
    fi
    
    echo "Preparing to flash $side side firmware..."
    echo "Firmware file: $firmware_file"
    echo ""
    
    # Find and select device
    local device
    device=$(select_device)
    
    echo ""
    echo "Flashing $side side firmware to $device..."
    
    # Copy firmware file
    if cp "$firmware_file" "$device/" 2>/dev/null; then
        echo "Firmware copied successfully!"
    else
        echo "Copy failed, device may be read-only. Trying with sudo..."
        if sudo cp "$firmware_file" "$device/"; then
            echo "Firmware copied successfully with sudo!"
        else
            echo "Error: Failed to copy firmware file to device even with sudo."
            echo "Please check that:"
            echo "1. The device is properly mounted"
            echo "2. There is enough space on the device"
            echo "3. The device path is correct: $device"
            exit 1
        fi
    fi
    
    echo ""
    echo "The device should auto-eject shortly..."
    echo "Flash complete! Safe to remove the $side side from USB."
    
    # Wait a moment for auto-eject
    sleep 2
    
    # Check if device is still mounted (some systems auto-eject, some don't)
    if [[ -d "$device" ]]; then
        echo "Note: Device is still mounted. You may need to safely eject it manually."
    fi
}

# Main script
if [[ $# -ne 1 ]]; then
    show_usage
fi

case "$1" in
    left|right)
        flash_firmware "$1"
        ;;
    *)
        echo "Error: Invalid argument '$1'"
        show_usage
        ;;
esac