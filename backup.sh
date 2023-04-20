#!/bin/bash

# Set the directory to be backed up
BACKUP_DIR="$HOME"

# Set the backup directory and log file paths
BACKUP_PATH="$HOME/backup"
CB_PREFIX="cb"
IB_PREFIX="ib"
LOG_PATH="$BACKUP_PATH/backup.log"

# Create the backup directory and its subdirectories if they do not exist
if [ ! -d "$BACKUP_PATH/cb" ]; then
    mkdir -p "$BACKUP_PATH/cb"
fi

if [ ! -d "$BACKUP_PATH/ib" ]; then
    mkdir -p "$BACKUP_PATH/ib"
fi

# Create the log file if it does not exist
if [ ! -f "$LOG_PATH" ]; then
    touch "$LOG_PATH"
fi

# Helper function to create tar archives
create_tar_archive() {
    local prefix="$1"
    local target_dir="$2"
    local output_dir="$3"
    local timestamp="$(date +"%a %d %b %Y %r %Z")"
    local archive_name="$prefix${LAST_CB_ARCHIVE_INDEX}.tar"
    tar -cf "$output_dir/$archive_name" "$target_dir" 2>/dev/null
    echo "$timestamp $archive_name was created"
}

# Helper function to update the log file
update_log() {
    local message="$1"
    echo "$message" >> "$LOG_PATH"
}

# Initialize the timestamp of the last complete backup and the index of the last complete backup archive
LAST_CB_TIMESTAMP=0
LAST_CB_ARCHIVE_INDEX=20000

# Initialize the index of the last incremental backup archive
LAST_IB_ARCHIVE_INDEX=10000

# Run the backup loop indefinitely
while true; do
    # Perform step 1: create a complete backup
    LAST_CB_ARCHIVE_INDEX=$((LAST_CB_ARCHIVE_INDEX+1))
    cb_archive_name="$(create_tar_archive "$CB_PREFIX" "$BACKUP_DIR" "$BACKUP_PATH/cb")"
    update_log "$cb_archive_name"

    # Wait for 2 minutes before performing the next steps
    sleep 120

    # Perform step 2: create an incremental backup
    if [[ "$(find "$BACKUP_DIR" -type f -name "*.txt" -newermt "@$LAST_CB_TIMESTAMP" 2>/dev/null | wc -l)" -gt 0 ]]; then
        LAST_IB_ARCHIVE_INDEX=$((LAST_IB_ARCHIVE_INDEX+1))
        ib_archive_name="$(create_tar_archive "$IB_PREFIX" "$BACKUP_DIR" "$BACKUP_PATH/ib")"
        update_log "$ib_archive_name"
    else
        update_log "$(date +"%a %d %b %Y %r %Z") No changes-Incremental backup was not created"
    fi

    # Update the timestamp of the last complete backup
    LAST_CB_TIMESTAMP="$(date +%s)"

    # Wait for 2 minutes before performing the next step
    sleep 120

    # Perform step 3: create another incremental backup
    if [[ "$(find "$BACKUP_DIR" -type f -name "*.txt" -newermt "@$LAST_IB_TIMESTAMP" 2>/dev/null | wc -l)" -gt 0 ]]; then
        LAST_IB_ARCHIVE_INDEX=$((LAST_IB_ARCHIVE_INDEX+1))
        ib_archive_name="$(create_tar_archive "$IB_PREFIX" "$BACKUP_DIR" "$BACKUP_PATH/ib")"
        update_log "$ib_archive_name"
    else
        update_log "$(date +"%a %d %b %Y %r %Z") No changes-Incremental backup was not created"
    fi

    # Update the timestamp of the last incremental backup
    LAST_IB_TIMESTAMP="$(date +%s)"

    # Wait for 2 minutes before performing the next step
    sleep 120

      # Perform step 4: create another incremental backup
    if [[ "$(find "$BACKUP_DIR" -type f -name "*.txt" -newermt "@$LAST_IB_TIMESTAMP" 2>/dev/null | wc -l)" -gt 0 ]]; then
        LAST_IB_ARCHIVE_INDEX=$((LAST_IB_ARCHIVE_INDEX+1))
        ib_archive_name="$(create_tar_archive "$IB_PREFIX" "$BACKUP_DIR" "$BACKUP_PATH/ib")"
        update_log "$ib_archive_name"
    else
        update_log "$(date +"%a %d %b %Y %r %Z") No changes-Incremental backup was not created"
    fi

    # Update the timestamp of the last incremental backup
    LAST_IB_TIMESTAMP="$(date +%s)"

    # Wait for 2 minutes before performing the next step
    sleep 120
done &
