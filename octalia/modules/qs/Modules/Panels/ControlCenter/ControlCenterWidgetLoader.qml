import QtQuick 6.10
import qs.Commons
import qs.Services.UI
import "./ControlCenterWidgetLoaderUtils.js" as ControlCenterWidgetLoaderUtils

Item {
  id: root

  required property string widgetId
  required property var widgetScreen
  required property var widgetProps

  property string section: ControlCenterWidgetLoaderUtils.field(widgetProps, "section") || ""
  property int sectionIndex: ControlCenterWidgetLoaderUtils.field(widgetProps, "sectionWidgetIndex") || 0

  // Don't reserve space unless the loaded widget is really visible
  implicitWidth: ControlCenterWidgetLoaderUtils.implicitSize(loader.item, "implicitWidth")
  implicitHeight: ControlCenterWidgetLoaderUtils.implicitSize(loader.item, "implicitHeight")

  Loader {
    id: loader
    anchors.fill: parent
    asynchronous: false

    Component.onCompleted: {
      sourceComponent = ControlCenterWidgetRegistry.getWidget(root.widgetId);
    }

    onLoaded: ControlCenterWidgetLoaderUtils.configureWidget(item, root.widgetProps, root.widgetScreen)

    Component.onDestruction: {
      // Explicitly clear references
      root.widgetProps = null;
    }
  }

  // Error handling
  Component.onCompleted: {
    if (!ControlCenterWidgetRegistry.hasWidget(widgetId)) {
      Logger.w("ControlCenterWidgetLoader", "Widget not found in registry:", widgetId);
      // Retry briefly in case the registry initializes after this component
      retryTimer.start();
    }
  }

  // Retry mechanism to cope with early evaluation before registry is ready
  Timer {
    id: retryTimer
    interval: 150
    repeat: true
    running: false
    property int attempts: 0
    onTriggered: {
      attempts += 1;
      if (ControlCenterWidgetRegistry.hasWidget(root.widgetId)) {
        loader.sourceComponent = ControlCenterWidgetRegistry.getWidget(root.widgetId);
        stop();
        attempts = 0;
        return;
      }
      if (attempts >= 20) { // ~3s max
        stop();
        attempts = 0;
        Logger.w("ControlCenterWidgetLoader", "Giving up waiting for widget:", root.widgetId);
      }
    }
  }
}
