pragma Singleton
import QtQuick
import Quickshell
import "AudioNodesModel.js" as Model

// Which PipeWire nodes the audio panel and the microphone widget leave out:
// the shell's own level meters, and the nodes a platform's audio processing
// adds, which its platform package names in the fixed platform root (see
// Model.parsePlatformAudio). No environment variable moves that file, and most
// machines have none, so nothing of theirs is left out.
Singleton {
  id: root

  // Windows has no platform audio hints file: nothing is hidden by it.
  property var hints: Model.parsePlatformAudio("")

  // Whether the platform's hints hide a node, given the names of every node
  // now in the graph (for a "replaced" node).
  function platformHides(name: var, nodeNames: var): bool {
    return Model.platformHidesNode(name, hints, nodeNames)
  }

  function isShellLevelMeter(name: var): bool {
    return Model.isShellLevelMeter(name)
  }
}
