import Quickshell

PersistentProperties {
    required final property ShellScreen modelData

    // Drawer visibilities
    final property bool bar
    final property bool osd
    final property bool session
    final property bool launcher
    final property bool dashboard
    final property bool utilities
    final property bool sidebar

    // Dashboard state
    final property int dashboardTab
    final property date dashboardDate: new Date()
}
