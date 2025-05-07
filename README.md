# GNOME Extensions Backup

A simple GNOME Shell extension to easily backup and restore your installed extensions and their configurations.

![GNOME Extensions Backup](https://i.imgur.com/3BDB22g.png)

## Features

- **One-click backup**: Create a complete backup of all your installed GNOME extensions
- **Easy restoration**: Restore your extensions with a single click
- **Configuration preservation**: Preserves all your extension settings
- **User-friendly interface**: Simple menu in the GNOME top panel

## How It Works

This extension adds an icon to your GNOME Shell top panel. Clicking on it shows a menu with two options:

- **Backup**: Creates a complete backup of all your enabled extensions, including:

  - List of extensions with installation URLs
  - Extension files (for local extensions)
  - Extension settings (via dconf)

- **Restore**: Restores your extensions from backup:
  - Reinstalls extensions from local backup if available
  - Imports all saved extension configurations
  - Provides a log of extensions that need manual installation

## Installation

### Manual Installation

1. Clone this repository:

   ```bash
   git clone https://github.com/IanBraga96/backup-gnome-extensions
   ```

2. Copy the extension to your GNOME extensions directory:

   ```bash
   cp -r gnome-extensions-backup ~/.local/share/gnome-shell/extensions/backup-gnome-extensions@gnome-shell-extensions.ianbraga.github.com
   ```

3. Restart GNOME Shell:

   - Press `Alt+F2`, type `r` and press Enter (X11)
   - Or log out and log back in (Wayland)

4. Enable the extension:
   ```bash
   gnome-extensions enable backup-gnome-extensions@gnome-shell-extensions.ianbraga.github.com
   ```

## Usage

### Creating a Backup

1. Click on the backup icon in the top panel
2. Select "Backup" from the dropdown menu
3. Your extensions will be backed up to `~/gnome-extensions-backup/`

### Restoring Extensions

1. Click on the backup icon in the top panel
2. Select "Restore Backup" from the dropdown menu
3. The extension will:
   - Restore all extensions from local backup
   - Apply saved configurations
   - Generate a log of extensions that need manual installation

### Backup Directory Structure

```
~/gnome-extensions-backup/
├── configs/                  # Extension configurations (dconf dumps)
├── extensions-data/          # Actual extension files
├── extensions-list.txt       # List of extensions with URLs
├── extensions-locations.txt  # Original locations of extensions
└── missing-extensions.log    # Log of extensions that need manual installation
```

## Troubleshooting

- If some extensions aren't working after restoration, check the `missing-extensions.log` file.
- For extensions that need manual installation, visit the URLs provided in the log file.
- If you encounter permission issues, make sure both script files in the `scripts` directory are executable:
  ```bash
  chmod +x ~/.local/share/gnome-shell/extensions/backup-gnome-extensions@gnome-shell-extensions.ianbraga.github.com/scripts/*.sh
  ```

## Development

### File Structure

```
backup-gnome-extensions@gnome-shell-extensions.ianbraga.github.com/
├── extension.js           # Main extension code
├── metadata.json          # Extension metadata
├── icons/
│   └── backup-icon.svg    # Extension icon
└── scripts/
    ├── extension-backup.sh # Backup script
    └── restore.sh         # Restore script
```

### Customization

You can use only scripts and can modify the scripts to include additional backup options or change the backup location:

1. Edit the `extension-backup.sh` and `restore.sh` files
2. Change the `BACKUP_DIR` variable to your preferred location

## License

This extension is released under the GNU General Public License v3.0 (GPL-3.0).

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## Acknowledgments

- The GNOME Shell team for providing the extensions API
- All the extension developers whose work is being backed up

---

If you encounter any issues or have any suggestions, please open an issue on GitHub.
