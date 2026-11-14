pragma Singleton

import "KeybindsUtils.js" as KeybindsUtils

import QtQuick 6.10

QtObject {
  id: root

  function getKeybindString(event: var): string {
    return KeybindsUtils.getKeybindString(event, Qt);
  }

  function checkKey(event: var, settingName: var, settings: var): bool {
    return KeybindsUtils.checkKey(event, settingName, settings, root);
  }

  /**
  * Check if a keybind string conflicts with any other existing keybinds.
  * @param {string} keyStr - The keybind string to check (e.g., "Ctrl+A").
  * @param {string} currentPath - The settings path of the keybind being edited (to skip checking itself).
  * @param {object} data - The settings data object (from Settings.data).
  * @returns {string|null} - The name of the conflicting action, or null if no conflict.
  */
  function getKeybindConflict(keyStr: var, currentPath: var, data: var): var {
    return KeybindsUtils.getKeybindConflict(keyStr, currentPath, data);
  }
}
