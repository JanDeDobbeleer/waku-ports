pragma Singleton
import QtQuick
import Quickshell

// The folders the shell reads and writes. All of them sit inside the port; nothing comes from the
// environment, so the shell starts the same way from any launcher.
QtObject {
  // The port folder (the config home waku was started with).
  readonly property string root: Quickshell.shellDir.replace(/\\/g, "/")
  // What the shell keeps between runs: the saved theme, notification history, toggles. Gitignored.
  readonly property string home: root + "/state/home"
  readonly property string stateHome: home + "/.local/state"
  readonly property string configHome: home + "/.config"
}
