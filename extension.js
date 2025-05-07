'use strict'
import GObject from 'gi://GObject'
import St from 'gi://St'
import Gio from 'gi://Gio'
import GLib from 'gi://GLib'
import {Extension} from 'resource:///org/gnome/shell/extensions/extension.js'
import * as PanelMenu from 'resource:///org/gnome/shell/ui/panelMenu.js'
import * as PopupMenu from 'resource:///org/gnome/shell/ui/popupMenu.js'
import * as Main from 'resource:///org/gnome/shell/ui/main.js'

const Indicator = GObject.registerClass(
  class Indicator extends PanelMenu.Button {
    _init(extension) {
      super._init(0.0, 'Backup Extensions')
      this._extension = extension

      // Icon for the button in the top panel
      this._icon = new St.Icon({
        gicon: Gio.icon_new_for_string(`${this._getIconPath()}/backup-icon.svg`),
        style_class: 'system-status-icon',
      })
      this.add_child(this._icon)

      // Create the menu
      this._createMenu()
    }

    _createMenu() {
      // "Backup" button
      const backupItem = new PopupMenu.PopupMenuItem('Backup')
      backupItem.connect('activate', () => {
        this._runScript(`${this._getScriptPath()}/extension-backup.sh`)
      })
      this.menu.addMenuItem(backupItem)

      // "Restore Backup" button
      const restoreItem = new PopupMenu.PopupMenuItem('Restore Backup')
      restoreItem.connect('activate', () => {
        this._runScript(`${this._getScriptPath()}/restore.sh`)
      })
      this.menu.addMenuItem(restoreItem)
    }

    _runScript(scriptPath) {
      try {
        GLib.spawn_command_line_async(`bash "${scriptPath}"`)
      } catch (e) {
        logError(e)
      }
    }

    _getScriptPath() {
      return `${this._extension.path}/scripts`
    }

    _getIconPath() {
      return `${this._extension.path}/icons`
    }
  },
)

export default class BackupExtensionIndicator extends Extension {
  enable() {
    this._indicator = new Indicator(this)
    Main.panel.addToStatusArea(this.uuid, this._indicator)
  }

  disable() {
    this._indicator.destroy()
    this._indicator = null
  }
}
