pragma Singleton
import Quickshell
import QtQuick

// What Octalia does with `mkdir -p`, `rm`, `wl-copy` and `xdg-open`, on Windows. Paths may use
// either slash; cmd.exe needs backslashes.
Singleton {
    function win(path: var): string {
        return String(path).replace(/\//g, "\\").replace(/\\+$/, "");
    }

    // Creates the folder and its parents (cmd's mkdir does), and does nothing when it exists.
    function mkdirp(path: var): void {
        const p = win(path);
        Quickshell.execDetached(["cmd", "/c", "if", "not", "exist", p, "mkdir", p]);
    }

    // Deletes a file, or a folder with everything in it when `recursive`.
    function rm(path, recursive) {
        const p = win(path);
        if (recursive)
            Quickshell.execDetached(["cmd", "/c", "rmdir", "/s", "/q", p]);
        else
            Quickshell.execDetached(["cmd", "/c", "del", "/f", "/q", p]);
    }

    function copy(text: var): void {
        Quickshell.clipboardText = String(text);
    }

    function open(url: var): void {
        Qt.openUrlExternally(url);
    }
}
