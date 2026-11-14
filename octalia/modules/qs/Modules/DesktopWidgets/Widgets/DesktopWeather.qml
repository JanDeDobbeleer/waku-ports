pragma ComponentBehavior: Bound

import QtQuick 6.10
import "../DesktopWidgetHelpers.js" as DesktopWidgetHelpers
import QtQuick.Layouts
import qs.Commons
import qs.Modules.DesktopWidgets
import qs.Services.Location
import qs.Widgets

DraggableDesktopWidget {
  id: root

  readonly property bool weatherReady: Settings.data.location.weatherEnabled && (DesktopWidgetHelpers.field(LocationService.data, "weather") !== null)
  readonly property int currentWeatherCode: weatherReady ? DesktopWidgetHelpers.currentWeatherField(DesktopWidgetHelpers.field(LocationService.data, "weather"), "weathercode") : 0
  readonly property real currentTemp: {
    if (!weatherReady)
      return 0;
    var temp = DesktopWidgetHelpers.currentWeatherField(DesktopWidgetHelpers.field(LocationService.data, "weather"), "temperature");
    if (Settings.data.location.useFahrenheit) {
      temp = LocationService.celsiusToFahrenheit(temp);
    }
    return Math.round(temp);
  }
  readonly property real todayMax: {
    if (!weatherReady || !DesktopWidgetHelpers.hasDailyWeather(DesktopWidgetHelpers.field(LocationService.data, "weather"), "temperature_2m_max"))
      return 0;
    var temp = DesktopWidgetHelpers.dailyWeatherValue(DesktopWidgetHelpers.field(LocationService.data, "weather"), "temperature_2m_max");
    if (Settings.data.location.useFahrenheit) {
      temp = LocationService.celsiusToFahrenheit(temp);
    }
    return Math.round(temp);
  }
  readonly property real todayMin: {
    if (!weatherReady || !DesktopWidgetHelpers.hasDailyWeather(DesktopWidgetHelpers.field(LocationService.data, "weather"), "temperature_2m_min"))
      return 0;
    var temp = DesktopWidgetHelpers.dailyWeatherValue(DesktopWidgetHelpers.field(LocationService.data, "weather"), "temperature_2m_min");
    if (Settings.data.location.useFahrenheit) {
      temp = LocationService.celsiusToFahrenheit(temp);
    }
    return Math.round(temp);
  }
  readonly property string tempUnit: Settings.data.location.useFahrenheit ? "F" : "C"
  readonly property string locationName: {
    const chunks = Settings.data.location.name.split(",");
    return chunks[0];
  }

  implicitWidth: Math.round(Math.max(240 * widgetScale, contentLayout.implicitWidth + Style.margin2M * widgetScale))
  implicitHeight: Math.round(64 * widgetScale + Style.margin2M * widgetScale)
  width: implicitWidth
  height: implicitHeight

  RowLayout {
    id: contentLayout
    anchors.fill: parent
    anchors.margins: Math.round(Style.marginM * root.widgetScale)
    spacing: Math.round(Style.marginM * root.widgetScale)
    z: 2

    Item {
      Layout.preferredWidth: Math.round(64 * root.widgetScale)
      Layout.preferredHeight: Math.round(64 * root.widgetScale)
      Layout.alignment: Qt.AlignVCenter

      NIcon {
        visible: !LocationService.taliaWeatherMascotActive || !root.weatherReady
        anchors.centerIn: parent
        icon: root.weatherReady ? LocationService.weatherSymbolFromCode(root.currentWeatherCode) : (LocationService.locationConfigured ? "weather-cloud-off" : "map-pin-off")
        pointSize: Math.round(Style.fontSizeXXXL * 2 * root.widgetScale)
        color: root.weatherReady ? Color.mPrimary : Color.mOnSurfaceVariant
      }
      Loader {
        active: LocationService.taliaWeatherMascotActive && root.weatherReady
        anchors.fill: parent
        asynchronous: true
        sourceComponent: Component {
          Image {
            anchors.fill: parent
            fillMode: Image.PreserveAspectFit
            smooth: true
            mipmap: true
            asynchronous: true
            source: Qt.resolvedUrl(LocationService.taliaWeatherImageFromCode(root.currentWeatherCode))
          }
        }
      }
    }

    NText {
      text: root.weatherReady ? `${root.currentTemp}°${root.tempUnit}` : "--"
      pointSize: Math.round(Style.fontSizeXXXL * root.widgetScale)
      font.weight: Style.fontWeightBold
      color: Color.mOnSurface
    }

    ColumnLayout {
      Layout.fillWidth: true
      spacing: Math.round(Style.marginXXS * root.widgetScale)
      Layout.alignment: Qt.AlignVCenter

      NText {
        Layout.fillWidth: true
        text: root.locationName || I18n.tr("common.weather-no-location")
        pointSize: Math.round(Style.fontSizeS * root.widgetScale)
        font.weight: Style.fontWeightRegular
        color: Color.mOnSurfaceVariant
        elide: Text.ElideRight
        maximumLineCount: 1
        visible: !Settings.data.location.hideWeatherCityName
      }

      RowLayout {
        spacing: Math.round(Style.marginXS * root.widgetScale)
        visible: root.weatherReady && root.todayMax > 0 && root.todayMin > 0

        NText {
          text: "H:"
          pointSize: Math.round(Style.fontSizeXS * root.widgetScale)
          color: Color.mOnSurfaceVariant
        }
        NText {
          text: `${root.todayMax}°`
          pointSize: Math.round(Style.fontSizeXS * root.widgetScale)
          color: Color.mOnSurface
        }

        NText {
          text: "•"
          pointSize: Math.round(Style.fontSizeXXS * root.widgetScale)
          color: Color.mOnSurfaceVariant
          opacity: 0.5
        }

        NText {
          text: "L:"
          pointSize: Math.round(Style.fontSizeXS * root.widgetScale)
          color: Color.mOnSurfaceVariant
        }
        NText {
          text: `${root.todayMin}°`
          pointSize: Math.round(Style.fontSizeXS * root.widgetScale)
          color: Color.mOnSurfaceVariant
        }
      }
    }
  }
}
