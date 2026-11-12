import QtQuick
import Quickshell.Io
import "Dynamic.js" as Dynamic

// One agent's usage record, read straight off the data file that
// nomarchy-agent-usage-update maintains. The panel never learns how the
// numbers were made — a record that appears in the usage directory is an
// agent, whoever wrote it.
Item {
  id: root
  visible: false

  property string agentId: ""
  property string path: ""
  property var record: null

  // The text the current record was parsed from, so a reload that finds the
  // file unchanged doesn't hand every listener an identical new record.
  property string parsedText: ""

  FileView {
    id: agentFile
    path: root.path
    watchChanges: true
    printErrors: false
    onFileChanged: reload()
    onLoaded: root.parse(text())
    onLoadFailed: root.clear()
  }

  // The usage update rewrites records with an atomic mv, which replaces the
  // inode. Should inotify fail to rearm on the new one (watch quota, ENOSPC),
  // the FileView goes quiet, so Main.qml also reloads every record after each
  // update run (#9974).
  function reload(): void { agentFile.reload() }

  function clear(): void {
    root.parsedText = ""
    root.record = null
  }

  function parse(content: string): void {
    var text = String(content || "")
    if (root.record && text === root.parsedText) return
    var result = Dynamic.parseRecord(text)
    if (result.ok) {
      root.record = result.record
      root.parsedText = root.record ? text : ""
    } else {
      console.warn("agents", "Ignoring bad usage record", root.path)
      root.clear()
    }
  }
}
