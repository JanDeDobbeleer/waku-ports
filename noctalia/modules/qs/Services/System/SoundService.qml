pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.compat

Singleton {
  id: root

  // Map to track active sound players: resolvedPath -> Process instance
  property var activePlayers: ({})

  // Windows has no QtMultimedia in the engine. Sounds are played by a hidden powershell.exe running
  // System.Windows.Media.MediaPlayer (wav, mp3, wma, aac, flac), which is always present.
  property bool multimediaAvailable: true

  // Container for dynamically created players
  Item {
    id: playersContainer
  }

  // Returns an absolute Windows path with backslashes, or "".
  function resolvePath(soundPath) {
    if (!soundPath || soundPath === "") {
      return "";
    }

    let p = String(soundPath).trim();

    // file:///D:/x.wav -> D:/x.wav
    if (p.startsWith("file:///")) {
      p = p.substring(8);
    } else if (p.startsWith("file://")) {
      p = p.substring(7);
    }
    if (/^\/[A-Za-z]:/.test(p)) {
      p = p.substring(1);
    }
    p = p.replace(/\\/g, "/");

    const isAbsolute = /^[A-Za-z]:\//.test(p) || p.startsWith("//");
    if (!isAbsolute) {
      const shell = String(Quickshell.shellDir).replace(/\\/g, "/").replace(/\/+$/, "");
      if (!p.includes("/")) {
        // Just a filename: bundled sound in Assets/Sounds
        p = shell + "/Assets/Sounds/" + p;
      } else {
        p = shell + "/" + p.replace(/^\/+/, "");
      }
    }
    return p.replace(/\//g, "\\");
  }

  function _psQuote(s) {
    return "'" + String(s).replace(/'/g, "''") + "'";
  }

  function playSound(soundPath, options) {
    if (!soundPath || soundPath === "") {
      Logger.w("SoundService", "No sound path provided");
      return;
    }

    const opts = options || {};
    const volume = Math.max(0, Math.min(1, opts.volume !== undefined ? opts.volume : 1.0));
    const fallback = opts.fallback !== undefined ? opts.fallback : false;
    const repeat = opts.repeat !== undefined ? opts.repeat : false;

    const resolvedPath = resolvePath(soundPath);
    if (resolvedPath === "") {
      return;
    }

    // Stop any existing player for this path if it's looping
    if (repeat && activePlayers[resolvedPath]) {
      stopSound(soundPath);
    }

    const script = "$ErrorActionPreference='Stop';" + "Add-Type -AssemblyName PresentationCore;" + "$p=New-Object System.Windows.Media.MediaPlayer;" + "$p.Open([Uri]" + _psQuote(resolvedPath) + ");" + "$p.Volume=" + volume.toFixed(3) + ";" + "$t=0;while(-not $p.NaturalDuration.HasTimeSpan -and $t -lt 50){Start-Sleep -Milliseconds 100;$t++};" + "if(-not $p.NaturalDuration.HasTimeSpan){exit 3};" + "$ms=[int]$p.NaturalDuration.TimeSpan.TotalMilliseconds+150;" + "do{$p.Position=[TimeSpan]::Zero;$p.Play();Start-Sleep -Milliseconds $ms}while(" + (repeat ? "$true" : "$false") + ");" + "$p.Close()";

    const playerQml = `
      import QtQuick
      import Quickshell.Io
      Process {
        property string resolvedPath: ""
        property bool shouldFallback: false
        property real soundVolume: 1.0
        property bool stopRequested: false
        stdout: StdioCollector {}
        stderr: StdioCollector {}
      }
    `;

    try {
      const player = Qt.createQmlObject(playerQml, playersContainer, "SoundPlayer_" + resolvedPath.replace(/[^a-zA-Z0-9]/g, "_"));
      if (!player) {
        Logger.w("SoundService", "Failed to create player for:", resolvedPath);
        return;
      }
      player.resolvedPath = resolvedPath;
      player.shouldFallback = fallback && !repeat;
      player.soundVolume = volume;
      player.exited.connect(function (exitCode, exitStatus) {
        if (exitCode !== 0 && !player.stopRequested) {
          Logger.w("SoundService", "Error playing sound:", resolvedPath, exitCode);
          if (player.shouldFallback) {
            const fallbackPath = Quickshell.shellDir + "/Assets/Sounds/notification-generic.wav";
            if (resolvePath(fallbackPath) !== resolvedPath) {
              playSound(fallbackPath, {
                          volume: player.soundVolume,
                          fallback: false,
                          repeat: false
                        });
            }
          }
        }
        if (activePlayers[resolvedPath] === player) {
          delete activePlayers[resolvedPath];
        }
        player.destroy();
      });
      player.command = ["powershell.exe", "-NoProfile", "-NonInteractive", "-ExecutionPolicy", "Bypass", "-WindowStyle", "Hidden", "-Command", script];
      activePlayers[resolvedPath] = player;
      player.running = true;

      Logger.d("SoundService", "Playing sound:", resolvedPath, `(volume: ${Math.round(volume * 100)}%)`, repeat ? "(repeat)" : "");
    } catch (e) {
      Logger.w("SoundService", "Failed to start sound player:", e);
    }
  }

  function _stopPlayer(player) {
    player.stopRequested = true;
    player.running = false;
  }

  function stopSound(soundPath) {
    if (soundPath) {
      const resolvedPath = resolvePath(soundPath);
      const player = activePlayers[resolvedPath];
      if (player) {
        delete activePlayers[resolvedPath];
        _stopPlayer(player);
        Logger.d("SoundService", "Stopped sound:", resolvedPath);
      }
    } else {
      const paths = Object.keys(activePlayers);
      for (let i = 0; i < paths.length; i++) {
        _stopPlayer(activePlayers[paths[i]]);
      }
      activePlayers = {};
      Logger.d("SoundService", "Stopped all sounds");
    }
  }
}
