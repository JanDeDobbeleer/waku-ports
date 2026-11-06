import Quickshell
import Quickshell.Wayland
import Celeste.Config

// qmllint disable uncreatable-type
PanelWindow {
    // qmllint enable uncreatable-type
    required property string name

    WlrLayershell.namespace: `celeste-${name}`
    color: "transparent"

}
