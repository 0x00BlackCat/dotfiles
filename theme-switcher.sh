#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

if ! command -v realpath >/dev/null 2>&1; then
    echo "[ERROR] realpath is required but not installed"
    exit 1
fi

usage() {
    echo "Usage: $0"
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help)
            usage
            exit 0
            ;;
        *)
            echo "[ERROR] Unknown option: $1"
            usage
            exit 1
            ;;
    esac
done

resolve_target_path() {
    local configured_path="$1"
    local expanded="$configured_path"

    if [[ "$expanded" == "~"* ]]; then
        expanded="${expanded/#\~/$HOME}"
    elif [[ "$expanded" != /* ]]; then
        expanded="$SCRIPT_DIR/$expanded"
    fi

    local resolved
    if ! resolved="$(realpath -m "$expanded" 2>/dev/null)"; then
        echo "[ERROR] Unable to resolve config path: $configured_path"
        return 1
    fi

    case "$resolved" in
        "$HOME"/*|"$SCRIPT_DIR"/*)
            printf '%s\n' "$resolved"
            ;;
        *)
            echo "[WARNING] Refusing to write outside \$HOME or repo directory: $resolved"
            return 1
            ;;
    esac
}


# Mapping of component names to their config files
declare -A COMPONENT_MAP=(
    ["waybar"]="waybar/colors.css"
    ["ghostty"]="ghostty/colors"
    ["mako"]="mako/colors.ini"
    ["hypr"]="hypr/colors.conf"
    ["nvim"]="~/.config/nvim/lua/custom/plugins/colorscheme.lua"
    ["wofi"]="wofi/style.css"
    ["btop"]="btop/themes/current.theme"
    ["hyprlock"]="hypr/hyprlock.conf"
)

# Get list of available themes
themes_dir="$SCRIPT_DIR/themes"
themes=()
for theme_dir in "$themes_dir"/*; do
    if [ -d "$theme_dir" ]; then
        themes+=("$(basename "$theme_dir")")
    fi
done

if [ ${#themes[@]} -eq 0 ]; then
    echo "ERROR: No themes found in $themes_dir"
    exit 1
fi

# Show theme selection with wofi
selected=$(printf '%s\n' "${themes[@]}" | wofi --dmenu --prompt "Select Theme")

if [ -z "$selected" ]; then
    exit 0
fi

THEME_NAME="$selected"
THEME_DIR="$SCRIPT_DIR/themes/$THEME_NAME"

if [ ! -d "$THEME_DIR" ]; then
    echo "ERROR: Theme directory '$THEME_DIR' does not exist"
    exit 1
fi

echo "Applying theme: $THEME_NAME"
echo ""

# Process each file in the theme directory
for theme_file in "$THEME_DIR"/*; do
    if [ ! -f "$theme_file" ]; then
        continue
    fi
    
    filename=$(basename "$theme_file")
    component_name="${filename%.*}"  # Remove extension
    
    # Check if we have a mapping for this component
    if [ -z "${COMPONENT_MAP[$component_name]:-}" ]; then
        echo "[WARNING] No mapping found for component '$component_name'. Skipping $filename"
        continue
    fi
    
    config_path="${COMPONENT_MAP[$component_name]}"

    if ! full_config_path="$(resolve_target_path "$config_path")"; then
        echo "[WARNING] Skipping $filename because the resolved path is not allowed."
        continue
    fi

    config_dir=$(dirname "$full_config_path")
    
    # Create config directory if it doesn't exist
    mkdir -p "$config_dir"

    
    # Copy theme file to config file
    cp -- "$theme_file" "$full_config_path"
    echo "[OK] Applied theme: $theme_file -> $full_config_path"
done

# Handle VS Code/Cursor theme
vscode_json="$THEME_DIR/vscode.json"
if [ -f "$vscode_json" ]; then
    # Check if jq is available for JSON parsing
    if command -v jq >/dev/null 2>&1; then
        theme_name=$(jq -r '.name' "$vscode_json")
        extension_id=$(jq -r '.extension' "$vscode_json")
        
        # Try Cursor first, then VS Code
        # Cursor: ~/.config/Cursor/User/settings.json
        # VS Code: ~/.config/Code/User/settings.json
        for editor_dir in "$HOME/.config/Cursor" "$HOME/.config/Code"; do
            if [ -d "$editor_dir" ]; then
                settings_file="$editor_dir/User/settings.json"
                editor_name=$(basename "$editor_dir")
                
                # Create settings.json if it doesn't exist
                if [ ! -f "$settings_file" ]; then
                    mkdir -p "$(dirname "$settings_file")"
                    echo "{}" > "$settings_file"
                fi
                
                # Update workbench.colorTheme using jq
                if jq --arg theme "$theme_name" '. + {"workbench.colorTheme": $theme}' "$settings_file" > "${settings_file}.tmp" 2>/dev/null; then
                    mv "${settings_file}.tmp" "$settings_file"
                    echo "[OK] Applied $editor_name theme: $theme_name"
                    echo "[INFO] Extension ID: $extension_id (make sure it's installed)"
                fi
            fi
        done
    else
        echo "[WARNING] jq not found. Install jq to enable VS Code/Cursor theme switching."
        echo "[INFO] Theme config: $(cat "$vscode_json")"
    fi
fi

echo ""
echo "Theme '$THEME_NAME' applied successfully!"

# Reload configurations
echo ""
echo "Reloading configurations..."

# Reload waybar
if pgrep -x waybar >/dev/null; then
    pkill waybar
    hyprctl dispatch exec waybar >/dev/null 2>&1 || true
    echo "[OK] Waybar reloaded"
fi

# Reload hyprland config
if command -v hyprctl >/dev/null 2>&1; then
    hyprctl reload >/dev/null 2>&1 || true
    echo "[OK] Hyprland config reloaded"
fi

# Reload mako if running
if pgrep -x mako >/dev/null; then
    pkill -USR1 mako 2>/dev/null || true
    echo "[OK] Mako reloaded"
    sleep 0.2
fi

# Reload ghostty if running
if pgrep -x ghostty >/dev/null; then
    killall -SIGUSR2 ghostty 2>/dev/null || true
    echo "[OK] Ghostty reloaded"
fi

# Reload btop if running
if pgrep -x btop >/dev/null; then
    pkill -SIGUSR2 btop 2>/dev/null || true
    echo "[OK] Btop reloaded"
fi

if command -v notify-send >/dev/null 2>&1; then
    notify-send "Theme Applied" "Using theme $THEME_NAME"
fi
