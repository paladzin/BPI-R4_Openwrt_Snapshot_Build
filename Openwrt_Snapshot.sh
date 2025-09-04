#!/bin/bash
# ==================================================================================
# BPI-R4 - OpenWrt with SnapShot Build Script
# ==================================================================================
# Please Note - IF you use the custom setup scripts for 'uci-defaults'.. As a precaution
#               they will be auto convert with the dos2unix tool to correct any DOS line
#               endings that may be present. Some users edit in windows and pass the
#               files across to the build system, which can causes errors in unix based
#               systems.
# Build system Install Note  - Run on Ubuntu 24.04 or later
#                            - sudo apt update
#                            - sudo apt install dos2unix
# Usage:
#
#   ./Openwrt_Snapshot.sh
#   ./Openwrt_Snapshot.sh -b openwrt-24.10
#
# ==================================================================================

set -euo pipefail

# --- Dependency Check ---
if ! command -v dos2unix &> /dev/null; then
    echo "ERROR: 'dos2unix' is not installed. Please run 'sudo apt update && sudo apt install dos2unix'." >&2
    exit 1
fi

readonly OPENWRT_REPO="https://git.openwrt.org/openwrt/openwrt.git"
OPENWRT_BRANCH="openwrt-24.10"

# To build a specific commit, paste the full hash here.
# To build the latest commit from the branch, leave this string empty (e.g., "").
readonly OPENWRT_COMMIT=""


# Define local directory names.
readonly OPENWRT_PATCHES_DIR="openwrt-patches"
readonly CONFIG_FILES_DIR="config"
readonly OPENWRT_DIR="openwrt"
readonly SCRIPT_EXECUTABLE_NAME=$(basename "$0")


# --- Functions ---
show_usage() {
    echo "Usage: $SCRIPT_EXECUTABLE_NAME [-b <branch_name>]"
    echo "  -b <branch_name>  Specify the OpenWrt branch to build (e.g., openwrt-23.05). Defaults to 'main'."
    exit 1
}

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

prompt_for_menuconfig() {
    log "--- Configuration Choice ---"
    echo "Would you like to run 'make menuconfig' to modify the configuration?"
    echo "You have 10 seconds to answer. The default is 'no' (use existing .config)."
    read -t 10 -p "Enter (yes/no): " user_choice || true

    case "${user_choice,,}" in
        y|yes)
            log "User chose 'yes'. Running 'make menuconfig'..."
            make menuconfig
            log "Saving a copy of the new configuration to '../$CONFIG_FILES_DIR/.config.new'..."
            cp .config "../$CONFIG_FILES_DIR/.config.new"
            log "New configuration saved."
            ;;
        n|no)
            log "User chose 'no'. Skipping 'make menuconfig'."
            ;;
        *)
            log "No input received within 10 seconds. Defaulting to 'no'."
            log "Skipping 'make menuconfig'."
            ;;
    esac
}

prepare_source_patches_and_files() {
    log "--- Preparing all source patches and custom files ---"

    if [ ! -d "$OPENWRT_PATCHES_DIR" ]; then
        log "No source patch directory ('$OPENWRT_PATCHES_DIR') found to process. Skipping."
        return
    fi

    log "Checking for and removing '.gitkeep' placeholders..."
    find "$OPENWRT_PATCHES_DIR" -type f -name ".gitkeep" -delete
    
    log "Running dos2unix on all source files..."
    find "$OPENWRT_PATCHES_DIR" -type f -exec dos2unix {} +

    log "Setting permissions on all source files and directories..."
    find "$OPENWRT_PATCHES_DIR" -type d -exec chmod 755 {} +
    find "$OPENWRT_PATCHES_DIR" -type f -exec chmod 644 {} +
    
    local uci_defaults_dir="$OPENWRT_PATCHES_DIR/files/etc/uci-defaults"
    if [ -d "$uci_defaults_dir" ]; then
         log "Making all uci-defaults scripts executable..."
         find "$uci_defaults_dir" -type f -exec chmod 755 {} +
    fi
    log "Source file processing complete."
}

apply_patches_and_files() {
    log "--- Applying custom patches and files from '$OPENWRT_PATCHES_DIR' ---"

    if [ ! -d "$OPENWRT_PATCHES_DIR" ] || [ -z "$(ls -A "$OPENWRT_PATCHES_DIR")" ]; then
        log "Source directory '$OPENWRT_PATCHES_DIR' not found or is empty. Nothing to apply."
        return
    fi
    
    log "Copying all content to the OpenWrt source directory..."
    cp -a "$OPENWRT_PATCHES_DIR/." "$OPENWRT_DIR/"
    log "All patches and files have been copied successfully."
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

        prompt_for_menuconfig

        log "Starting the build... This could take a very long time."
        make "-j$(nproc)" V=s
    )
    log "--- Build process finished successfully! ---"
}


# --- Main Execution ---
main() {
    while getopts ":b:" opt; do
        case ${opt} in
            b )
                OPENWRT_BRANCH=$OPTARG
                ;;
            \? )
                echo "Invalid Option: -$OPTARG" 1>&2
                show_usage
                ;;
            : )
                echo "Invalid Option: -$OPTARG requires an argument" 1>&2
                show_usage
                ;;
        esac
    done
    shift "$((OPTIND -1))"

    log "--- Starting OpenWrt Setup ---"
    log "Using OpenWrt branch: $OPENWRT_BRANCH"
    
    require_command "git"
    require_command "awk"
    require_command "make"

    local target_commit
    if [ -n "$OPENWRT_COMMIT" ]; then
        target_commit="$OPENWRT_COMMIT"
        log "Using specified commit hash: $target_commit"
    else
        target_commit=$(get_latest_commit_hash "$OPENWRT_REPO" "$OPENWRT_BRANCH")
        log "Latest commit hash for '$OPENWRT_BRANCH' is: $target_commit"
    fi

    setup_openwrt_repo "$OPENWRT_REPO" "$OPENWRT_BRANCH" "$target_commit" "$OPENWRT_DIR"
    
    prepare_source_patches_and_files

    apply_patches_and_files
    
    run_openwrt_build
    
    log "--- You can find the output images in '$OPENWRT_DIR/bin/targets/mediatek/filogic/' ---"
}

main "$@"

exit 0
