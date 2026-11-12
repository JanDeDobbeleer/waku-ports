pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import "InputMethodData.js" as Data

Singleton {
  id: root
  property var state: ({})

  function cycle(back: var): bool {
    if (!watcher.running) return false
    watcher.write(back ? "cycle back\n" : "cycle\n")
    return true
  }

  // One reader and pending selection for every monitor's keyboard widget.
  Process {
    id: watcher
    command: ["/usr/bin/python3", (Quickshell.env("NOMARCHY_PATH") || "") + "/default/input-methods/indicator.py"]
    running: true
    stdinEnabled: true
    stdout: SplitParser {
      onRead: function(data: string): void { Data.update(root, data) }
    }
    onExited: {
      root.state = ({})
      restart.restart()
    }
  }

  Timer {
    id: restart
    interval: 5000
    onTriggered: watcher.running = true
  }
}
