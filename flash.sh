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

find_and_mount_nicenano_devices() {
    local devices=()
    
    # First, check already mounted devices with common names
    for mount_point in "/run/media/$USER/NICENANO" "/media/$USER/NICENANO" "/mnt/NICENANO" \
                       "/run/media/$USER/RPI-RP2" "/media/$USER/RPI-RP2" "/mnt/RPI-RP2"; do
        if [[ -d "$mount_point" ]]; then
            devices+=("$mount_point")
        fi
    done
    
    # Search for NICENANO or RPI-RP2 in all mount points
    while IFS= read -r -d '' device; do
        if [[ "$device" == *"NICENANO"* || "$device" == *"RPI-RP2"* ]]; then
            devices+=("$device")
        fi
    done < <(find /run/media /media /mnt 2>/dev/null -maxdepth 3 \( -name "*NICENANO*" -o -name "*RPI-RP2*" \) -type d -print0 2>/dev/null || true)
    
    # Check for unmounted NICENANO devices and try to mount them
    while IFS= read -r line; do
        local device_name label mount_point device_path
        device_name=$(echo "$line" | awk '{print $1}')
        label=$(echo "$line" | awk '{print $2}')
        mount_point=$(echo "$line" | awk '{print $3}')
        
        # Ensure device path starts with /dev/
        if [[ "$device_name" == /dev/* ]]; then
            device_path="$device_name"
        else
            device_path="/dev/$device_name"
        fi
        
        if [[ "$label" == "NICENANO" || "$label" == "RPI-RP2" ]] && [[ -z "$mount_point" || "$mount_point" == "" ]]; then
            echo "Found unmounted NICENANO device: $device_path" >&2
            
            # Try to mount using udisksctl (preferred method)
            if command -v udisksctl >/dev/null 2>&1; then
                echo "Mounting $device_path using udisksctl..." >&2
                if mount_output=$(udisksctl mount -b "$device_path" 2>&1); then
                    # Extract mount point from udisksctl output (format: "Mounted /dev/xxx at /path/to/mount")
                    new_mount_point=$(echo "$mount_output" | sed -n 's/.*at \(\/.*\)\.*/\1/p')
                    if [[ -n "$new_mount_point" && -d "$new_mount_point" ]]; then
                        echo "Successfully mounted at: $new_mount_point" >&2
                        devices+=("$new_mount_point")
                    fi
                else
                    echo "Failed to mount with udisksctl: $mount_output" >&2
                fi
            else
                # Fallback to manual mount
                local fallback_mount="/run/media/$USER/NICENANO"
                echo "udisksctl not available, trying manual mount to $fallback_mount..." >&2
                
                if sudo mkdir -p "$fallback_mount" && sudo mount "$device_path" "$fallback_mount"; then
                    echo "Successfully mounted at: $fallback_mount" >&2
                    devices+=("$fallback_mount")
                else
                    echo "Failed to manually mount $device_path" >&2
                fi
            fi
        fi
    done < <(lsblk -nr -o NAME,LABEL,MOUNTPOINT | grep -E "(NICENANO|RPI-RP2)" || true)
    
    # Remove duplicates
    printf '%s\n' "${devices[@]}" | sort -u
}

select_device() {
    local devices
    mapfile -t devices < <(find_and_mount_nicenano_devices)
    
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