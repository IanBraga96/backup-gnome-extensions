#!/bin/bash

BACKUP_DIR="$HOME/gnome-extensions-backup"
CONFIG_DIR="$BACKUP_DIR/configs"
EXT_LIST_FILE="$BACKUP_DIR/extensions-list.txt"
EXT_LOCATIONS_FILE="$BACKUP_DIR/extensions-locations.txt"
EXT_DATA_DIR="$BACKUP_DIR/extensions-data"
MISSING_EXT_LOG="$BACKUP_DIR/missing-extensions.log"

if [ ! -f "$EXT_LIST_FILE" ]; then
  echo "❌ File extensions-list.txt not found in $EXT_LIST_FILE"
  exit 1
fi

# Creates the temporary directory for downloads
TMP_DIR="$BACKUP_DIR/tmp"
mkdir -p "$TMP_DIR"
mkdir -p "$HOME/.local/share/gnome-shell/extensions"

# Gets the GNOME Shell version
GNOME_SHELL_VERSION=$(gnome-shell --version | awk '{print $3}' | cut -d. -f1,2)
echo "🔍 Detected GNOME Shell version: $GNOME_SHELL_VERSION"

# Initializes the log file for missing extensions
echo "# Extensions that need to be installed manually" > "$MISSING_EXT_LOG"
echo "# Generated on: $(date)" >> "$MISSING_EXT_LOG"
echo "# --------------------------------------------" >> "$MISSING_EXT_LOG"
echo "" >> "$MISSING_EXT_LOG"

# Counter for missing extensions
missing_count=0

# Reads the list and activates the extensions
ACTIVE_EXTENSIONS=()
while IFS= read -r line; do
  # Ignores empty lines
  if [ -z "$line" ]; then
    continue
  fi
  
  ext=$(echo "$line" | cut -d ' ' -f 1)
  url=$(echo "$line" | cut -d ' ' -f 2-)
  
  # Ignores extensions without a name
  if [ -z "$ext" ]; then
    continue
  fi
  
  echo "🔌 Processing extension: $ext"
  
  # Checks if the extension is already installed
  if [ ! -d "$HOME/.local/share/gnome-shell/extensions/$ext" ] && [ ! -d "/usr/share/gnome-shell/extensions/$ext" ]; then
    echo "🌐 Extension not installed, trying to restore from local backup: $ext"
    
    # Checks if a local backup of the extension exists
    if [ -d "$EXT_DATA_DIR/$ext" ]; then
      echo "📦 Local backup found, restoring..."
      
      # Creates the extension directory
      EXT_DIR="$HOME/.local/share/gnome-shell/extensions/$ext"
      mkdir -p "$EXT_DIR"
      
      # Copies files from backup
      cp -r "$EXT_DATA_DIR/$ext"/* "$EXT_DIR"/ || {
        echo "⚠️ Error copying backup files for: $ext"
        continue
      }
      
      echo "✅ Extension $ext restored from local backup."
    else
      echo "⚠️ Local backup not found for: $ext"
      echo "⚠️ Please install the extension manually: $ext"
      echo "📎 Possible URL: $url"
      
      # Adds the extension to the log file
      ((missing_count++))
      echo "## $missing_count. $ext" >> "$MISSING_EXT_LOG"
      echo "- **Search name:** ${ext%%@*}" >> "$MISSING_EXT_LOG"
      echo "- **URL (if available):** $url" >> "$MISSING_EXT_LOG"
      echo "" >> "$MISSING_EXT_LOG"
      
      # Tries to provide a hint about finding the extension online as a last resort
      if [[ "$url" == *"extensions.gnome.org"* ]]; then
        echo "ℹ️ Tip: You can install this extension by visiting the GNOME Extensions website and searching for '${ext%%@*}'"
        echo "- **Tip:** Visit https://extensions.gnome.org and search for '${ext%%@*}'" >> "$MISSING_EXT_LOG"
        echo "" >> "$MISSING_EXT_LOG"
      fi
    fi
  else
    echo "✅ Extension $ext already installed."
  fi
  
  # Activates the extension
  gnome-extensions enable "$ext" 2>/dev/null || echo "⚠️ Could not activate: $ext"
  
  # Restores extension settings
  clean_name="${ext%%@*}"
  dconf_file="$CONFIG_DIR/$ext.dconf"
  if [ -f "$dconf_file" ]; then
    echo "🔁 Restoring settings for: $ext"
    dconf load "/org/gnome/shell/extensions/$clean_name/" < "$dconf_file"
  else
    echo "⚠️ Configuration file not found for: $ext"
  fi
  
  # Adds to the list of active extensions
  ACTIVE_EXTENSIONS+=("$ext")
done < "$EXT_LIST_FILE"

# Updates the list of extensions in GNOME - using correct format with quotes
extensions_array=()
for ext in "${ACTIVE_EXTENSIONS[@]}"; do
  if [ -n "$ext" ]; then  # Checks if not empty
    extensions_array+=("'$ext'")
  fi
done

# Builds the string in the correct format for gsettings
extensions_string="[$(IFS=, ; echo "${extensions_array[*]}")]"
echo "📦 Updating extension list in GNOME"
gsettings set org.gnome.shell enabled-extensions "$extensions_string"

# Cleans temporary directory
rm -rf "$TMP_DIR"

# Displays the summary of missing extensions
if [ $missing_count -gt 0 ]; then
  echo ""
  echo "⚠️ $missing_count extensions need to be installed manually"
  echo "📝 Check the log file: $MISSING_EXT_LOG"
else
  echo "✅ All extensions were successfully restored!"
fi

echo "✅ Restoration completed!"