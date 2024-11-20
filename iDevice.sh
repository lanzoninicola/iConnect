#!/bin/bash
#------------------------------------------------------
# Author:   Levoo Minds
# Version:  4
#------------------------------------------------------
#------------------------------------------------------
# Function: log_message
# Description: Logs a message with a timestamp to the log file.
#------------------------------------------------------
log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

#------------------------------------------------------
# Function: check_and_install_package
# Description: Checks if a package is installed and installs it if missing.
#------------------------------------------------------
check_and_install_package() {
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

#------------------------------------------------------
# Function: validate_device
# Description: Validates the connection of an iDevice.
#------------------------------------------------------
validate_device() {
    if idevicepair validate | grep -q "No"; then
        log_message "No iDevice detected. Connect your iDevice and allow access."
        return 1
    fi
    log_message "iDevice detected successfully."
    return 0
}

#------------------------------------------------------
# Function: prepare_mount_path
# Description: Ensures the mount path exists, creates it if not.
#------------------------------------------------------
prepare_mount_path() {
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

#------------------------------------------------------
# Function: unmount_if_needed
# Description: Unmounts the device if it is already mounted.
#------------------------------------------------------
unmount_if_needed() {
    if mountpoint -q "$MOUNT_PATH"; then
        log_message "Device already mounted at $MOUNT_PATH. Unmounting..."
        umount "$MOUNT_PATH"
        if [ $? -ne 0 ]; then
            log_message "Failed to unmount $MOUNT_PATH. Exiting."
            exit 1
        fi
    fi
}

#------------------------------------------------------
# Function: mount_device
# Description: Mounts the iDevice to the specified path.
#------------------------------------------------------
mount_device() {
    log_message "Mounting iDevice to $MOUNT_PATH..."
    ifuse "$MOUNT_PATH" &>>"$LOG_FILE"
    if [ $? -eq 0 ]; then
        log_message "iDevice mounted successfully at $MOUNT_PATH."
    else
        log_message "Failed to mount iDevice. Check the log for details."
        exit 1
    fi
}

#------------------------------------------------------
# Function: main
# Description: Main execution flow of the script.
#------------------------------------------------------
main() {
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

#------------------------------------------------------
# Variables:
#------------------------------------------------------
LOG_FILE="$HOME/iDevice.log"
PACKAGE="ifuse"
MOUNT_PATH="$HOME/iDevice"

#------------------------------------------------------
# MAIN: Entrypoint
#------------------------------------------------------
main
