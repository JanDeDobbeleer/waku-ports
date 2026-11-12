import Quickshell
import Quickshell.Wayland

// qmllint disable uncreatable-type
PanelWindow {
    // qmllint enable uncreatable-type
    required property string windowName

    WlrLayershell.namespace: `celeste-${windowName}`
    color: "transparent"

}
