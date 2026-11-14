import QtQuick 6.10
import QtQuick.Layouts
import qs.Commons
import qs.Widgets
import "../CardSettings.js" as CardSettingsData

ColumnLayout {
  id: root
  spacing: Style.marginL
  Layout.fillWidth: true

  property list<var> cardsModel: []
  property list<var> cardsDefault: [
    {
      "id": "calendar-header-card",
      "text": I18n.tr("panels.location.calendar-header-label"),
      "enabled": true,
      "required": true
    },
    {
      "id": "calendar-month-card",
      "text": I18n.tr("panels.location.calendar-month-label"),
      "enabled": true,
      "required": false
    },
    {
      "id": "weather-card",
      "text": I18n.tr("common.weather"),
      "enabled": true,
      "required": false
    }
  ]

  function saveCards(): void {
    CardSettingsData.saveCards(cardsModel, Settings.data.calendar, "cards");
  }

  Component.onCompleted: CardSettingsData.initializeCalendarCards(root, cardsDefault, Settings.data.calendar.cards, Settings.data.location.weatherEnabled)

  // Clock style section
  ColumnLayout {
    spacing: Style.marginM
    Layout.fillWidth: true

    NToggle {
      label: I18n.tr("panels.location.date-time-use-analog-label")
      description: I18n.tr("panels.location.date-time-use-analog-description")
      checked: Settings.data.location.analogClockInCalendar
      onToggled: checked => Settings.data.location.analogClockInCalendar = checked
    }

    NToggle {
      label: I18n.tr("panels.location.date-time-week-numbers-label")
      description: I18n.tr("panels.location.date-time-week-numbers-description")
      checked: Settings.data.location.showWeekNumberInCalendar
      onToggled: checked => Settings.data.location.showWeekNumberInCalendar = checked
    }
  }

  NDivider {
    Layout.fillWidth: true
  }

  // Calendar Cards Management Section
  ColumnLayout {
    spacing: Style.marginXXS
    Layout.fillWidth: true

    Connections {
      target: Settings.data.location
      function onWeatherEnabledChanged(): void {
        CardSettingsData.setWeatherEnabled(root, Settings.data.location.weatherEnabled);
      }
    }

    NReorderCheckboxes {
      Layout.fillWidth: true
      model: root.cardsModel
      disabledIds: Settings.data.location.weatherEnabled ? [] : ["weather-card"]
      onItemToggled: function (index, enabled) {
        var newModel = root.cardsModel.slice();
        newModel[index] = Object.assign({}, newModel[index], {
                                          "enabled": enabled
                                        });
        root.cardsModel = newModel;
        root.saveCards();
      }
      onItemsReordered: function (fromIndex, toIndex) {
        var newModel = root.cardsModel.slice();
        var item = newModel.splice(fromIndex, 1)[0];
        newModel.splice(toIndex, 0, item);
        root.cardsModel = newModel;
        root.saveCards();
      }
    }
  }
}
