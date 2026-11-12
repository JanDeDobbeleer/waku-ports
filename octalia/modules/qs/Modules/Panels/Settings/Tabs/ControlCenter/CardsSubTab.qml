import QtQuick 6.10
import QtQuick.Layouts
import qs.Commons
import qs.Widgets
import "../CardSettings.js" as CardSettingsData

ColumnLayout {
  id: root
  spacing: Style.marginL
  Layout.fillWidth: true
  Layout.fillHeight: true

  required property var cardsModel
  required property list<var> cardsDefault

  function saveCards(): void {
    CardSettingsData.saveCards(root.cardsModel, Settings.data.controlCenter, "cards");
  }


    NText {
      text: I18n.tr("panels.control-center.cards-desc")
      wrapMode: Text.WordWrap
      Layout.fillWidth: true
    }

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
