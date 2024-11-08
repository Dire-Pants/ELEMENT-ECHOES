#!/bin/bash

# Ensure an acronym is provided
if [[ -z "$1" ]]; then
    echo "$(date '+%Y-%m-%d %H:%M:%S') - Usage: $0 <acronym>"
    exit 1
fi

# Instance acronym
ACRONYM="$1"
# Directory to watch
WATCH_DIR="/mnt/project-docs/ee_element-echo/public"
# File to store the last checksum
CHECKSUM_FILE="/tmp/${ACRONYM}_vault_checksum.txt"
# Directory of the Quartz instance
QUARTZ_DIR="/home/$ACRONYM"
# Command to run
COMMAND="npx quartz sync"
# Log file
LOG_FILE="/tmp/check-changes-$ACRONYM.log"

# Calculate the current checksum of the directory
CURRENT_CHECKSUM=$(find "$WATCH_DIR" -type f -exec md5sum {} + | md5sum)

# Function to log with a timestamp
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
}

# Check if the checksum file exists
if [[ -f "$CHECKSUM_FILE" ]]; then
    # Compare with the last recorded checksum
    LAST_CHECKSUM=$(cat "$CHECKSUM_FILE")
    if [[ "$CURRENT_CHECKSUM" != "$LAST_CHECKSUM" ]]; then
        log "Changes detected in $WATCH_DIR. Running command..."
        cd "$QUARTZ_DIR" || exit
        if $COMMAND; then
            log "Command executed successfully."
        else
            log "Error executing command."
        fi
        # Update the checksum file
        echo "$CURRENT_CHECKSUM" > "$CHECKSUM_FILE"
    else
        log "No changes detected in $WATCH_DIR."
    fi
else
    # If the checksum file doesn't exist, create it
    echo "$CURRENT_CHECKSUM" > "$CHECKSUM_FILE"
    log "Checksum file created."
fi

# Rotate the log file to keep only the last 50 lines
tail -n 50 "$LOG_FILE" > "${LOG_FILE}.tmp" && mv "${LOG_FILE}.tmp" "$LOG_FILE"
