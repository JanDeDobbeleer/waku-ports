import QtQuick 6.10
import QtQuick.Layouts
import qs.Commons
import qs.Services.UI
import qs.Widgets
import "ControlCenterTab.js" as ControlCenterTabData

ColumnLayout {
  id: root
  spacing: 0

  property list<var> cardsModel: []
  property list<var> cardsDefault: [
    {
      "id": "profile-card",
      "text": "Profile",
      "enabled": true,
      "required": true
    },
    {
      "id": "shortcuts-card",
      "text": "Shortcuts",
      "enabled": true,
      "required": false
    },
    {
      "id": "audio-card",
      "text": "Audio Sliders",
      "enabled": true,
      "required": false
    },
    {
      "id": "brightness-card",
      "text": "Brightness",
      "enabled": false,
      "required": false
    },
    {
      "id": "weather-card",
      "text": "Weather",
      "enabled": true,
      "required": false
    },
    {
      "id": "media-sysmon-card",
      "text": "Media and System Monitor",
      "enabled": true,
      "required": false
    }
  ]

  Component.onCompleted: {
    var card, found, i, j;
    // Fill out availableWidgets ListModel
    availableWidgets.clear();
    var sortedEntries = Array.from(ControlCenterWidgetRegistry.getAvailableWidgets()).sort();
    sortedEntries.forEach(entry => {
                            const displayName = entry;
                            const badges = [];
                            availableWidgets.append({
                                                      "key": entry,
                                                      "name": displayName,
                                                      "badges": badges
                                                    });
                          });
    // Starts empty
    cardsModel = [];

    // Add the cards available in settings
    for (i = 0; i < Settings.data.controlCenter.cards.length; i++) {
      const settingCard = Settings.data.controlCenter.cards[i];

      for (j = 0; j < cardsDefault.length; j++) {
        if (settingCard.id === cardsDefault[j].id) {
          card = cardsDefault[j];
          card.enabled = settingCard.enabled;
          // Auto-disable weather card if weather is disabled
          if (card.id === "weather-card" && !Settings.data.location.weatherEnabled) {
            card.enabled = false;
          }
          cardsModel.push(card);
        }
      }
    }

    // Add any missing cards from default
    for (i = 0; i < cardsDefault.length; i++) {
      found = false;
      for (j = 0; j < cardsModel.length; j++) {
        if (cardsModel[j].id === cardsDefault[i].id) {
          found = true;
          break;
        }
      }

      if (!found) {
        card = cardsDefault[i];
        // Auto-disable weather card if weather is disabled
        if (card.id === "weather-card" && !Settings.data.location.weatherEnabled) {
          card.enabled = false;
        }
        cardsModel.push(card);
      }
    }
  }

  NTabBar {
    id: subTabBar
    Layout.fillWidth: true
    Layout.bottomMargin: Style.marginM
    distributeEvenly: true
    currentIndex: tabView.currentIndex

    NTabButton {
      text: I18n.tr("common.appearance")
      tabIndex: 0
      checked: subTabBar.currentIndex === 0
    }
    NTabButton {
      text: I18n.tr("common.cards")
      tabIndex: 1
      checked: subTabBar.currentIndex === 1
    }
    NTabButton {
      text: I18n.tr("common.shortcuts")
      tabIndex: 2
      checked: subTabBar.currentIndex === 2
    }
  }

  Item {
    Layout.fillWidth: true
    Layout.preferredHeight: Style.marginL
  }

  NTabView {
    id: tabView
    currentIndex: subTabBar.currentIndex
    Layout.fillWidth: true
    Layout.fillHeight: true

    AppearanceSubTab {}

    CardsSubTab {
      cardsModel: root.cardsModel
      cardsDefault: root.cardsDefault
    }

    ShortcutsSubTab {
      availableWidgets: availableWidgets
      onAddWidgetToSection: (widgetId, section) => root._addWidgetToSection(widgetId, section)
      onRemoveWidgetFromSection: (section, index) => root._removeWidgetFromSection(section, index)
      onReorderWidgetInSection: (section, fromIndex, toIndex) => root._reorderWidgetInSection(section, fromIndex, toIndex)
      onUpdateWidgetSettingsInSection: (section, index, settings) => root._updateWidgetSettingsInSection(section, index, settings)
      onMoveWidgetBetweenSections: (fromSection, index, toSection) => root._moveWidgetBetweenSections(fromSection, index, toSection)
    }
  }

  // ---------------------------------
  // Signal functions
  // ---------------------------------
  function _addWidgetToSection(widgetId: string, section: string): void {
    ControlCenterTabData.addWidget(Settings.data.controlCenter, ControlCenterWidgetRegistry, widgetId, section);
  }

  function _removeWidgetFromSection(section: string, index: int): void {
    ControlCenterTabData.removeWidget(Settings.data.controlCenter, section, index);
  }

  function _reorderWidgetInSection(section: string, fromIndex: int, toIndex: int): void {
    ControlCenterTabData.reorderWidget(Settings.data.controlCenter, section, fromIndex, toIndex);
  }

  function _moveWidgetBetweenSections(fromSection: string, index: int, toSection: string): void {
    ControlCenterTabData.moveWidget(Settings.data.controlCenter, fromSection, index, toSection);
  }

  function _updateWidgetSettingsInSection(section: string, index: int, settings: var): void {
    ControlCenterTabData.updateWidgetSettings(Settings.data.controlCenter, section, index, settings, Settings);
  }

  // Base list model for all combo boxes
  ListModel {
    id: availableWidgets
  }
}
