import QtQuick 6.10
import Quickshell
import qs.Commons

Variants {
  model: {
    const screens = Quickshell.screens.filter(screen => Settings.data.notifications.monitors.includes(screen.name));
    // Empty list can mean two things :
    // - No (visible) notification display activated in settings
    // - One or more (not visible) displays are activated but unplugged
    // In both cases we fallback to show notification on all screens
    return screens.length === 0 ? Quickshell.screens : screens;
  }

  delegate: ToastScreen {
    required property ShellScreen modelData
    screen: modelData
  }
}
