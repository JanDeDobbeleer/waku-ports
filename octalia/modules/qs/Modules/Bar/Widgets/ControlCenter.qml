import QtQuick 6.10
import Quickshell
import Quickshell.Widgets
import qs.Commons
import qs.Modules.Panels.Settings
import qs.Services.System
import qs.Services.UI
import qs.Widgets
import qs.compat

NIconButton {
  id: root

  property ShellScreen screen

  // Widget properties passed from Bar.qml for per-instance settings
  property string widgetId: ""
  property string section: ""
  property int sectionWidgetIndex: -1
  property int sectionWidgetsCount: 0

  property var widgetMetadata: BarWidgetRegistry.widgetMetadata[widgetId] ?? {}
  // Explicit screenName property ensures reactive binding when screen changes
  readonly property string screenName: screen ? screen.name : ""
  property var widgetSettings: {
    var widgets;
    if (section && sectionWidgetIndex >= 0 && screenName) {
      widgets = Settings.getBarWidgetsForScreen(screenName)[section];
      if (widgets && sectionWidgetIndex < widgets.length) {
        return widgets[sectionWidgetIndex];
      }
    }
    return {};
  }

  readonly property string customIcon: widgetSettings.icon !== undefined ? widgetSettings.icon : widgetMetadata.icon
  readonly property bool useDistroLogo: widgetSettings.useDistroLogo !== undefined ? widgetSettings.useDistroLogo : widgetMetadata.useDistroLogo
  readonly property string customIconPath: widgetSettings.customIconPath !== undefined ? widgetSettings.customIconPath : widgetMetadata.customIconPath
  readonly property bool enableColorization: widgetSettings.enableColorization !== undefined ? widgetSettings.enableColorization : widgetMetadata.enableColorization
  readonly property string colorizeSystemIcon: widgetSettings.colorizeSystemIcon !== undefined ? widgetSettings.colorizeSystemIcon : widgetMetadata.colorizeSystemIcon

  readonly property color iconColor: {
    if (!enableColorization)
      return Color.mOnSurface;
    return Color.resolveColorKey(colorizeSystemIcon);
  }

  // If we have a custom path and not using distro logo, use the theme icon.
  // If using distro logo, don't use theme icon.
  icon: (customIconPath === "" && !useDistroLogo) ? customIcon : ""
  baseSize: Style.getCapsuleHeightForScreen(screen?.name)
  applyUiScale: false
  customRadius: Style.radiusL
  colorBg: Style.capsuleColor
  colorFg: iconColor
  colorBgHover: Color.mHover
  colorFgHover: Color.mOnHover
  colorBorder: Style.capsuleBorderColor
  colorBorderHover: Style.capsuleBorderColor

  NPopupContextMenu {
    id: contextMenu

    model: [
      {
        "label": I18n.tr("actions.open-launcher"),
        "action": "open-launcher",
        "icon": "search"
      },
      {
        "label": I18n.tr("actions.open-settings"),
        "action": "open-settings",
        "icon": "adjustments"
      },
      {
        "label": I18n.tr("actions.widget-settings"),
        "action": "widget-settings",
        "icon": "settings"
      },
    ]

    onTriggered: action => {
      var panel;
                   contextMenu.close();
                   PanelService.closeContextMenu(screen);

                   if (action === "open-launcher") {
                     PanelService.toggleLauncher(screen);
                   } else if (action === "open-settings") {
                     panel = PanelService.getPanel("settingsPanel", screen);
                     panel.requestedTab = SettingsPanel.Tab.General;
                     panel.toggle();
                   } else if (action === "widget-settings") {
                     BarService.openWidgetSettings(screen, root.section, root.sectionWidgetIndex, root.widgetId, root.widgetSettings);
                   }
                 }
  }

  onClicked: {
    var controlCenterPanel = PanelService.getPanel("controlCenterPanel", screen);
    if (Settings.data.controlCenter.position === "close_to_bar_button") {
      // Will open the panel next to the bar button.
      controlCenterPanel?.toggle(this);
    } else {
      controlCenterPanel?.toggle();
    }
  }
  onRightClicked: {
    PanelService.showContextMenu(contextMenu, root, screen);
  }
  onMiddleClicked: PanelService.toggleLauncher(screen)

  IconImage {
    id: customOrDistroLogo
    anchors.centerIn: parent
    width: root.buttonSize * 0.8
    height: width
    source: {
      if (root.useDistroLogo)
        return HostService.osLogo;
      if (root.customIconPath !== "")
        return root.customIconPath.startsWith("file://") ? root.customIconPath : "file:///" + root.customIconPath.replace(/[\\]/g, "/");
      return "";
    }
    visible: source !== ""
    smooth: true
    asynchronous: true
    layer.enabled: (root.enableColorization) && (root.useDistroLogo || root.customIconPath !== "")
    layer.effect: ShaderEffect {
      property color targetColor: !hovering ? iconColor : Color.mOnHover
      property real colorizeMode: 2.0

      fragmentShader: Qt.resolvedUrl(ShellUrl.dir + "/Shaders/qsb/appicon_colorize.frag.qsb")
    }
  }
}
