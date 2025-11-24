#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

if ! command -v realpath >/dev/null 2>&1; then
    echo "[ERROR] realpath is required but not installed"
    exit 1
fi

trim() {
    local value="$1"
    value="${value#"${value%%[![:space:]]*}"}"
    value="${value%"${value##*[![:space:]]}"}"
    printf '%s\n' "$value"
}

resolve_within_home() {
    local target="$1"
    local resolved
    if ! resolved="$(realpath -m "$target" 2>/dev/null)"; then
        echo "[ERROR] Unable to resolve path: $target" >&2
        return 1
    fi

    case "$resolved" in
        "$HOME"/*)
            printf '%s\n' "$resolved"
            ;;
        *)
            echo "[ERROR] Refusing to create files outside \$HOME: $resolved" >&2
            return 1
            ;;
    esac
}

symlinkFile() {
    local relative_path="$1"
    local destination_dir="$2"
    local source_file="$SCRIPT_DIR/$relative_path"

    if [ ! -e "$source_file" ]; then
        echo "[ERROR] Source file not found: $source_file"
        return 1
    fi

    local destination_candidate
    if [ -z "$destination_dir" ]; then
        destination_candidate="$HOME/$(basename "$relative_path")"
    else
        destination_candidate="$HOME/$destination_dir/$(basename "$relative_path")"
    fi

    local destination
    if ! destination="$(resolve_within_home "$destination_candidate")"; then
        return 1
    fi

    mkdir -p "$(dirname "$destination")"

    if [ -L "$destination" ]; then
        echo "[WARNING] $destination already symlinked"
        return 0
    fi

    if [ -e "$destination" ]; then
        echo "[ERROR] $destination exists but it's not a symlink. Please fix that manually"
        return 1
    fi

    ln -s "$source_file" "$destination"
    echo "[OK] $source_file -> $destination"
}

deployManifest() {
    local manifest="$1"
    while IFS='|' read -r raw_filename raw_operation raw_destination || [ -n "${raw_filename}${raw_operation}${raw_destination}" ]; do
        local filename
        filename="$(trim "${raw_filename:-}")"

        if [ -z "$filename" ] || [[ "$filename" == \#* ]]; then
            continue
        fi

        local operation
        operation="$(trim "${raw_operation:-}")"
        local destination
        destination="$(trim "${raw_destination:-}")"

        case "$operation" in
            symlink)
                symlinkFile "$filename" "$destination"
                ;;
            "")
                echo "[WARNING] No operation provided for entry '$filename'. Skipping..."
                ;;
            *)
                echo "[WARNING] Unknown operation '$operation'. Skipping..."
                ;;
        esac
    done < "$manifest"
}

if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <MANIFEST>"
    exit 1
fi

manifest_path="$1"
if [[ "$manifest_path" != /* ]]; then
    manifest_path="$SCRIPT_DIR/$manifest_path"
fi

if [ ! -f "$manifest_path" ]; then
    echo "[ERROR] Manifest file not found: $manifest_path"
    exit 1
fi

deployManifest "$manifest_path"
