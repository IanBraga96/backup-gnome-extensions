#!/bin/bash

BACKUP_DIR="$HOME/gnome-extensions-backup"
CONFIG_DIR="$BACKUP_DIR/configs"
EXT_LIST_FILE="$BACKUP_DIR/extensions-list.txt"
EXT_LOCATIONS_FILE="$BACKUP_DIR/extensions-locations.txt"
EXT_DATA_DIR="$BACKUP_DIR/extensions-data"

mkdir -p "$CONFIG_DIR"
mkdir -p "$EXT_DATA_DIR"

# Gets list of active extensions
ACTIVE_EXTENSIONS=$(gsettings get org.gnome.shell enabled-extensions | sed "s/\['//;s/'\]//;s/', '/\n/g")

# Clear files before adding
> "$EXT_LIST_FILE"
> "$EXT_LOCATIONS_FILE"

# Process each active extension
for ext in $ACTIVE_EXTENSIONS; do
    # Remove single quotes (if they exist)
    clean_name=$(echo $ext | tr -d "'")
    
    # Ignore empty lines
    if [ -z "$clean_name" ]; then
        continue
    fi
    
    echo "🔍 Processing extension: $clean_name"
    
    # Try to locate the extension in the system
    extension_path=""
    
    # Search in common locations
    for location in "$HOME/.local/share/gnome-shell/extensions" "/usr/share/gnome-shell/extensions"; do
        if [ -d "$location/$clean_name" ]; then
            extension_path="$location/$clean_name"
            break
        fi
    done
    
    if [ -n "$extension_path" ]; then
        echo "📂 Extension found at: $extension_path"
        
        # Save the extension path
        echo "$clean_name $extension_path" >> "$EXT_LOCATIONS_FILE"
        
        # Copy the extension files (for local backup)
        echo "📦 Copying extension files..."
        target_dir="$EXT_DATA_DIR/$clean_name"
        mkdir -p "$target_dir"
        cp -r "$extension_path"/* "$target_dir"/ 2>/dev/null
        
        # Extract UUID and URL of the extension from metadata.json if available
        if [ -f "$extension_path/metadata.json" ]; then
            # Look for extension URL in metadata.json
            url=$(grep -o '"url"[[:space:]]*:[[:space:]]*"[^"]*"' "$extension_path/metadata.json" | sed 's/"url"[[:space:]]*:[[:space:]]*"//;s/"$//' || echo "")
            
            if [ -z "$url" ]; then
                # Try to find homepage as an alternative
                url=$(grep -o '"homepage"[[:space:]]*:[[:space:]]*"[^"]*"' "$extension_path/metadata.json" | sed 's/"homepage"[[:space:]]*:[[:space:]]*"//;s/"$//' || echo "")
            fi
            
            # If still no URL, try to get it from _source in metadata
            if [ -z "$url" ]; then
                url=$(grep -o '"_source"[[:space:]]*:[[:space:]]*"[^"]*"' "$extension_path/metadata.json" | sed 's/"_source"[[:space:]]*:[[:space:]]*"//;s/"$//' || echo "")
            fi
            
            # If no URL found, use a generic URL based on the extension name
            if [ -z "$url" ]; then
                # Remove the @... from the name to create a slug
                base_name="${clean_name%%@*}"
                url="https://extensions.gnome.org/extension-query/?search=$base_name"
            fi

            # Save the extension and URL to the file
            echo "$clean_name $url" >> "$EXT_LIST_FILE"
            echo "✅ Saved $clean_name with URL: $url"
        else
            echo "⚠️ Metadata not found for: $clean_name"
            echo "$clean_name https://extensions.gnome.org" >> "$EXT_LIST_FILE"
        fi
        
        # Save extension settings via dconf
        base_name="${clean_name%%@*}"
        echo "🔧 Saving configuration for: $base_name"
        dconf dump "/org/gnome/shell/extensions/$base_name/" > "$CONFIG_DIR/$clean_name.dconf"
        
        # Check if the configuration file has content
        if [ -s "$CONFIG_DIR/$clean_name.dconf" ]; then
            echo "📦 Settings saved for: $clean_name"
        else
            echo "ℹ️ No configuration found for: $clean_name"
        fi
    else
        echo "⚠️ Could not find extension: $clean_name"
        echo "$clean_name https://extensions.gnome.org" >> "$EXT_LIST_FILE"
    fi
done

echo "✅ Backup completed and saved to: $BACKUP_DIR"
echo "📋 Total extensions saved: $(grep -c . "$EXT_LIST_FILE")"
echo "🗂️ Complete backup directory: $EXT_DATA_DIR"