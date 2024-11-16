#!/bin/bash
# Version: 1.0
# Description: A script to detect, mount, and interact with an iDevice using ifuse.
# Author: Levoo Minds

# Variables
LOG_FILE="$HOME/iDevice.log"
PACKAGE="ifuse"
MOUNT_PATH="$HOME/iDevice"

# Functions
log_message() {
    # Logs a message with timestamp
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

check_and_install_package() {
    # Checks if the required package is installed, installs if missing
    if ! dpkg -s "$1" &>/dev/null; then
        log_message "Package $1 not found. Installing..."
        sudo apt update && sudo apt install "$1" libimobiledevice-utils -y
        if [ $? -eq 0 ]; then
            log_message "Package $1 installed successfully."
        else
            log_message "Failed to install $1. Exiting."
            exit 1
        fi
    else
        log_message "Package $1 is already installed."
    fi
}

validate_device() {
    # Validates the iDevice connection
    if idevicepair validate | grep -q "No"; then
        log_message "No iDevice detected. Connect your iDevice and allow access."
        return 1
    fi
    log_message "iDevice detected successfully."
    return 0
}

prepare_mount_path() {
    # Prepares the mount path
    if [ ! -d "$MOUNT_PATH" ]; then
        log_message "Mount path $MOUNT_PATH does not exist. Creating..."
        mkdir -p "$MOUNT_PATH"
        if [ $? -ne 0 ]; then
            log_message "Failed to create mount path $MOUNT_PATH. Exiting."
            exit 1
        fi
        log_message "Mount path $MOUNT_PATH created successfully."
    fi
}

unmount_if_needed() {
    # Unmounts the device if it is already mounted
    if mountpoint -q "$MOUNT_PATH"; then
        log_message "Device already mounted at $MOUNT_PATH. Unmounting..."
        umount "$MOUNT_PATH"
        if [ $? -ne 0 ]; then
            log_message "Failed to unmount $MOUNT_PATH. Exiting."
            exit 1
        fi
    fi
}

mount_device() {
    # Mounts the iDevice to the specified path
    log_message "Mounting iDevice to $MOUNT_PATH..."
    ifuse "$MOUNT_PATH" &>>"$LOG_FILE"
    if [ $? -eq 0 ]; then
        log_message "iDevice mounted successfully at $MOUNT_PATH."
    else
        log_message "Failed to mount iDevice. Check the log for details."
        exit 1
    fi
}

main() {
    # Main script execution
    log_message "Starting iDevice manager script."

    # Check and install required package
    check_and_install_package "$PACKAGE"

    # Wait for iDevice connection
    until validate_device; do
        log_message "Retrying in 10 seconds..."
        sleep 10
    done

    # Infinite loop for mounting
    while true; do
        prepare_mount_path
        unmount_if_needed
        mount_device

        # Open the mount path
        xdg-open "$MOUNT_PATH"
        read -t 10 -p "Press Enter to refresh or wait 10 seconds to retry..."
    done
}

# Execute the main function
main
