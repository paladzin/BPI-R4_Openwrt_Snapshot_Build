#!/bin/bash
# ==================================================================================
# BPI-R4 - OpenWrt with SnapShot Build Script
# ==================================================================================
# Please Note - IF you use the custom setup scripts for 'uci-defaults'.. As a precaution
#                 they will be auto convert with the dos2unix tool to correct any DOS line
#                 endings that may be present. Some users edit in windows and pass the
#                 files across to the build system, which can causes errors in unix based
#                 systems.
# Build system Install Note  - Run on Ubuntu 24.04 or later
#                            - sudo apt update
#                            - sudo apt install dos2unix
# Usage:
#
#   ./Openwrt_Snapshot.sh
#
# ==================================================================================

set -euo pipefail

# --- Dependency Check ---
if ! command -v dos2unix &> /dev/null; then
    echo "ERROR: 'dos2unix' is not installed. Please run 'sudo apt update && sudo apt install dos2unix'." >&2
    exit 1
fi

# --- uci-defaults Scripts Selectable Options ---
# Change this variable to select a different setup script from the 'scripts' directory.
# To use - SETUP_SCRIPT_NAME="999-simple-dumb_AP-wifi-Setup.sh" or "" (an empty string) to skip this step entirely.
readonly SETUP_SCRIPT_NAME="999-simple-dumb_AP-wifi-Setup.sh"


# Define OpenWrt repository details. The commit hash for latest commint will be determined at runtime.
readonly OPENWRT_REPO="https://git.openwrt.org/openwrt/openwrt.git"
readonly OPENWRT_BRANCH="main"                                        # Branch can be changed to "openwrt-24.10" , "master" , "main" etc...

# Define local directory names.
readonly SOURCE_PATCH_DIR="patches"
readonly SOURCE_FILES_DIR="files"
readonly SETUP_SCRIPT_SOURCE_DIR="scripts"
readonly CONFIG_FILES_DIR="config"
readonly OPENWRT_DIR="openwrt"
readonly SCRIPT_EXECUTABLE_NAME=$(basename "$0")


# --- Functions ---

log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] - $1" >&2
}

require_command() {
    if ! command -v "$1" &> /dev/null; then
        log "Error: Required command '$1' is not installed. Please install it and try again."
        exit 1
    fi
}

get_latest_commit_hash() {
    local repo_url=$1
    local branch=$2
    
    log "Querying remote repository for the latest commit on branch '$branch'..."
    
    local commit_hash
    commit_hash=$(git ls-remote "$repo_url" "refs/heads/$branch" | awk '{print $1}')
    
    if [ -z "$commit_hash" ]; then
        log "Error: Could not retrieve the commit hash for branch '$branch'."
        log "Please check the repository URL and branch name."
        exit 1
    fi
    
    echo "$commit_hash"
}

setup_openwrt_repo() {
    local repo_url=$1
    local branch=$2
    local commit_hash=$3
    local target_dir=$4

    if [ -d "$target_dir" ]; then
        log "Directory '$target_dir' already exists. Removing it for a fresh clone."
        rm -rf "$target_dir"
        log "Old directory removed."
    fi

    log "Cloning repository..."
    git clone --branch "$branch" "$repo_url" "$target_dir"
    log "Clone complete. Checking out specific commit: $commit_hash"
    (cd "$target_dir" && git checkout "$commit_hash")
    log "Successfully checked out commit."
}
# --- Applies all patches from the patches directory to the build tree ---
#         - You can edit add, delete or "" any of the below patches to your liking...
apply_patches() {
    log "--- Applying custom patches ---"

    if [ ! -d "$SOURCE_PATCH_DIR" ]; then
        log "No patch directory ('$SOURCE_PATCH_DIR') found. Skipping."
        return
    fi
	
	# Various hardware and software patches
    log "Applying hardware and software patches..."
    cp "$SOURCE_PATCH_DIR/200-v.kosikhin-libiwinfo-fix_noise_reading_for_radios.patch" "$OPENWRT_DIR/package/network/utils/iwinfo/patches/"
	
	# BPI-R4 - BE14 pathces - fix EEPROM issues with the faulty BE14 cards.. (Comment out the below patches, if your card doesn't have EEPROM issues)
	log "Applying patches for the faulty BE14 EEPROM cards..."
    local target_dirs=("$OPENWRT_DIR"/target/linux/mediatek/patches-6.*)
	
	if [[ ${#target_dirs[@]} -eq 1 && -d "${target_dirs[0]}" ]]; then
        local final_target_dir="${target_dirs[0]}/subsys"
        log "Found target patch directory: $final_target_dir"
        mkdir -p "$final_target_dir"
        cp "$SOURCE_PATCH_DIR/999-mt7988a-bananapi-bpi-r4-BE14000-binmode.patch" "$final_target_dir/"
    else
        log "Warning: Could not find target/linux/mediatek/ patch directory matching 'patches-6.*'."
        log "Found ${#target_dirs[@]} matches, skipping patch. Check path: $OPENWRT_DIR/target/linux/mediatek/"
    fi
	
}

# --- Prepares custom configuration files, scripts, and permissions.
#           - Do not change any thing below this point.. (unless you know what your doing of course ;) 
prepare_custom_files() {
    log "--- Preparing custom files and scripts ---"
    
    local target_files_root="$OPENWRT_DIR/files"

    log "Checking for custom files in '$SOURCE_FILES_DIR' directory..."
    if [ ! -d "$SOURCE_FILES_DIR" ]; then
        log "Source directory '$SOURCE_FILES_DIR' not found. Skipping custom file copy."
    else
        log "Checking for and removing '.gitkeep' placeholders..."
        find "$SOURCE_FILES_DIR" -type f -name ".gitkeep" -delete

        if [ -n "$(find "$SOURCE_FILES_DIR" -type f)" ]; then
            log "Found custom files. Copying to '$target_files_root'..."
            mkdir -p "$target_files_root"
            cp -a "$SOURCE_FILES_DIR"/. "$target_files_root/"
        else
            log "No custom files to copy. Skipping."
        fi
    fi

    if [ -n "$SETUP_SCRIPT_NAME" ]; then
        local script_source_path="$SETUP_SCRIPT_SOURCE_DIR/$SETUP_SCRIPT_NAME"
        local uci_defaults_path="$target_files_root/etc/uci-defaults"

        log "Setup script is defined: '$SETUP_SCRIPT_NAME'. Looking for it at '$script_source_path'..."

        if [ ! -f "$script_source_path" ]; then
            log "==================================================================="
            log "  ERROR: Setup script not found at: $script_source_path"
            log "==================================================================="
            exit 1
        fi
        
        log "Adding setup script to uci-defaults..."
        mkdir -p "$uci_defaults_path"
        cp "$script_source_path" "$uci_defaults_path/"
    else
        log "No setup script selected (SETUP_SCRIPT_NAME is empty). Skipping uci-defaults."
    fi

    if [ -d "$target_files_root" ]; then
        log "Running dos2unix on all files in '$target_files_root'..."
        find "$target_files_root" -type f -exec dos2unix {} +

        log "Setting permissions on copied files and directories..."
        find "$target_files_root" -type d -exec chmod 755 {} +
        find "$target_files_root" -type f -exec chmod 644 {} +
        
        if [ -d "$target_files_root/etc/uci-defaults" ]; then
             log "Making all uci-defaults scripts executable..."
             find "$target_files_root/etc/uci-defaults" -type f -exec chmod 755 {} +
        fi
    fi
}

run_openwrt_build() {
    log "--- Starting OpenWrt Build Process ---"

    (
        cd "$OPENWRT_DIR"

        log "Updating and installing feeds..."
        ./scripts/feeds update -a
        ./scripts/feeds install -a

        log "Applying custom build configuration from '../$CONFIG_FILES_DIR'..."
        if [ ! -d "../$CONFIG_FILES_DIR" ]; then
            log "No custom config directory ('$CONFIG_FILES_DIR') found. Skipping."
        else
            if [ -f "../$CONFIG_FILES_DIR/.config" ]; then
                log "Copying main .config file..."
                cp "../$CONFIG_FILES_DIR/.config" .
            fi
            if [ -f "../$CONFIG_FILES_DIR/.mlo_config" ]; then
                log "Appending .mlo_config settings..."
                echo -e "\n" >> .config
                cat "../$CONFIG_FILES_DIR/.mlo_config" >> .config
            fi
        fi

        log "Validating and expanding final .config..."
        make defconfig

        log "Starting the build... This could take a very long time."
        make "-j$(nproc)" V=s
    )
    log "--- Build process finished successfully! ---"
}


# --- Main Execution ---
main() {
    log "--- Starting OpenWrt Setup ---"
    
    require_command "git"
    require_command "awk"
    require_command "make"

    local target_commit
    target_commit=$(get_latest_commit_hash "$OPENWRT_REPO" "$OPENWRT_BRANCH")
    log "Latest commit hash for '$OPENWRT_BRANCH' is: $target_commit"

    setup_openwrt_repo "$OPENWRT_REPO" "$OPENWRT_BRANCH" "$target_commit" "$OPENWRT_DIR"
    
    apply_patches

    prepare_custom_files
    
    run_openwrt_build
    
    log "--- You can find the output images in '$OPENWRT_DIR/bin/targets/mediatek/filogic/' ---"
}

# Run the main function.
main

exit 0

