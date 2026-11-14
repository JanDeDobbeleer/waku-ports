pragma ComponentBehavior: Bound

import "NSearchableComboBoxUtils.js" as ComboUtils

import QtQuick 6.10
import QtQuick.Controls.Basic
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

RowLayout {
  id: root

  property real minimumWidth: 280
  property real popupHeight: 180

  property bool selectOnNavigation: true
  property string label: ""
  property string description: ""
  property ListModel model: null
  property string currentKey: ""
  property string placeholder: ""
  property string searchPlaceholder: I18n.tr("placeholders.search")
  property Component delegate: null
  property var defaultValue: undefined
  property string settingsPath: ""

  readonly property real preferredHeight: Math.round(Style.baseWidgetSize * 1.1)

  signal selected(string key)

  spacing: Style.marginL
  Layout.fillWidth: true

  readonly property bool isValueChanged: (defaultValue !== undefined) && (currentKey !== defaultValue)

  // Filtered model for search results
  property ListModel filteredModel: ListModel {}
  property string searchText: ""

  function findIndexByKey(key: var): int {
    return ComboUtils.findIndexByKey(root.model, key);
  }

  // The active model used for the popup list (source model or filtered results)
  readonly property ListModel activeModel: isFiltered ? filteredModel : root.model

  function findIndexInActiveModel(key: var): int {
    return ComboUtils.findIndexInActiveModel(activeModel, key);
  }

  // Whether we're using filtered results or the source model directly
  property bool isFiltered: false

  function filterModel() {
    var fuzzyResults, i, item, j, searchLower;
    // Check if model exists and has items
    if (!root.model || ComboUtils.modelCount(root.model) === undefined || ComboUtils.modelCount(root.model) === 0) {
      ComboUtils.clearModel(filteredModel);
      isFiltered = false;
      return;
    }

    var query = searchText.trim();
    if (query === "") {
      // No search text - use source model directly, don't copy
      ComboUtils.clearModel(filteredModel);
      isFiltered = false;
      return;
    }

    // We have search text - need to filter
    isFiltered = true;
    ComboUtils.clearModel(filteredModel);

    // Convert ListModel to array for fuzzy search
    var items = [];
    for (i = 0; i < ComboUtils.modelCount(root.model); i++) {
      items.push(ComboUtils.getItem(root.model, i));
    }

    // Use fuzzy search if available, fallback to simple search
    if (typeof FuzzySort !== 'undefined') {
      fuzzyResults = FuzzySort.go(query, items, {
                                        "key": "name",
                                        "limit": 50
                                      });

      // Add results in order of relevance
      for (j = 0; j < fuzzyResults.length; j++) {
        ComboUtils.appendItem(filteredModel, fuzzyResults[j].obj);
      }
    } else {
      // Fallback to simple search
      searchLower = query.toLowerCase();
      for (i = 0; i < items.length; i++) {
        item = items[i];
        if (ComboUtils.modelName(item).toLowerCase().includes(searchLower)) {
          ComboUtils.appendItem(filteredModel, item);
        }
      }
    }
  }

  onSearchTextChanged: {
    filterModel();
    listView.currentIndex = 0;
  }

  NLabel {
    label: root.label
    description: root.description
    showIndicator: root.isValueChanged
  }

  Item {
    Layout.fillWidth: true
  }

  ComboBox {
    id: combo

    opacity: enabled ? 1.0 : 0.6
    Layout.margins: Style.borderS
    Layout.minimumWidth: Math.round(root.minimumWidth * Style.uiScaleRatio)
    Layout.preferredHeight: Math.round(root.preferredHeight * Style.uiScaleRatio)
    implicitWidth: Layout.minimumWidth
    model: root.activeModel
    textRole: "name"
    currentIndex: root.findIndexInActiveModel(root.currentKey)
    onActivated: {
      if (combo.currentIndex >= 0 && root.activeModel && combo.currentIndex < ComboUtils.modelCount(root.activeModel)) {
        root.selected(ComboUtils.modelKey(root.activeModel, combo.currentIndex));
      }
    }

    background: Rectangle {
      implicitWidth: Math.round(Style.baseWidgetSize * 3.75 * Style.uiScaleRatio)
      implicitHeight: Math.round(root.preferredHeight * Style.uiScaleRatio)
      color: Color.mSurface
      border.color: combo.activeFocus ? Color.mSecondary : Color.mOutline
      border.width: Style.borderS
      radius: Style.iRadiusM

      Behavior on border.color {
        ColorAnimation {
          duration: Style.animationFast
        }
      }
    }

    contentItem: NText {
      leftPadding: Style.marginL
      rightPadding: combo.indicator.width + Style.marginL
      pointSize: Style.fontSizeM
      verticalAlignment: Text.AlignVCenter
      elide: Text.ElideRight

      // Look up current selection directly in source model by key
      readonly property int sourceIndex: root.findIndexByKey(root.currentKey)
      readonly property bool hasSelection: root.model && sourceIndex >= 0 && sourceIndex < ComboUtils.modelCount(root.model)

      color: hasSelection ? Color.mOnSurface : Color.mOnSurfaceVariant
      text: hasSelection ? ComboUtils.modelItemName(root.model, sourceIndex) : root.placeholder
    }

    indicator: NIcon {
      x: combo.width - width - Style.marginM
      y: combo.topPadding + (combo.availableHeight - height) / 2
      icon: "caret-down"
      pointSize: Style.fontSizeL
    }

    popup: Popup {
      y: combo.height + Style.marginS
      width: combo.width
      height: Math.round((root.popupHeight + 60) * Style.uiScaleRatio)
      padding: Style.marginM

      contentItem: ColumnLayout {
        spacing: Style.marginS

        // Search input
        NTextInput {
          id: searchInput
          inputIconName: "search"
          Layout.fillWidth: true
          placeholderText: root.searchPlaceholder
          text: root.searchText
          onTextChanged: root.searchText = text
          fontSize: Style.fontSizeS

          Keys.onPressed: event => {
                            if (Keybinds.checkKey(event, 'enter', Settings)) {
                              selectHighlighted();
                              ComboUtils.closePopup(combo.popup);
                              event.accepted = true;
                              return;
                            }

                            if (Keybinds.checkKey(event, 'escape', Settings)) {
                              ComboUtils.closePopup(combo.popup);
                              event.accepted = true;
                              return;
                            }

                            if (Keybinds.checkKey(event, 'up', Settings)) {
                              if (listView.currentIndex > 0) {
                                listView.currentIndex--;
                                if (root.selectOnNavigation)
                                selectHighlighted();
                              }
                              event.accepted = true;
                              return;
                            }

                            if (Keybinds.checkKey(event, 'down', Settings)) {
                              if (listView.currentIndex < listView.count - 1) {
                                listView.currentIndex++;
                                if (root.selectOnNavigation)
                                selectHighlighted();
                              }
                              event.accepted = true;
                              return;
                            }
                          }

          function selectHighlighted() {
            var selectedKey;
            if (listView.currentIndex >= 0 && listView.model && listView.currentIndex < ComboUtils.modelCount(listView.model)) {
              selectedKey = ComboUtils.modelKey(listView.model, listView.currentIndex);
              root.selected(selectedKey);
            }
          }
        }

        NListView {
          id: listView
          Layout.fillWidth: true
          Layout.fillHeight: true
          // Use activeModel (source model when not filtering, filtered results when searching)
          model: combo.popup.visible ? root.activeModel : null
          horizontalPolicy: ScrollBar.AlwaysOff
          verticalPolicy: ScrollBar.AsNeeded

          onCurrentIndexChanged: {
            if (currentIndex >= 0)
              positionViewAtIndex(currentIndex, ListView.Contain);
          }

          delegate: root.delegate ? root.delegate : defaultDelegate

          Component {
            id: defaultDelegate
            ItemDelegate {
              id: delegateRoot
              required property var model
              required property int index
              width: listView.availableWidth
              leftPadding: Style.marginM
              rightPadding: Style.marginM
              topPadding: Style.marginS
              bottomPadding: Style.marginS
              hoverEnabled: true
              highlighted: listView.currentIndex === delegateRoot.index

              onHoveredChanged: {
                if (hovered) {
                  listView.currentIndex = delegateRoot.index;
                }
              }

              onClicked: {
                var selectedKey = ComboUtils.modelKey(listView.model, delegateRoot.index);
                root.selected(selectedKey);
                ComboUtils.closePopup(combo.popup);
              }

              contentItem: RowLayout {
                width: delegateRoot.width - delegateRoot.leftPadding - delegateRoot.rightPadding
                spacing: Style.marginM

                NText {
                  text: ComboUtils.modelName(delegateRoot.model)
                  pointSize: Style.fontSizeM
                  color: delegateRoot.highlighted ? Color.mOnHover : Color.mOnSurface
                  verticalAlignment: Text.AlignVCenter
                  elide: Text.ElideRight
                  Layout.fillWidth: true
                }

                RowLayout {
                  spacing: Style.marginXXS
                  Layout.alignment: Qt.AlignRight

                  // Generic badge renderer
                  Repeater {
                    model: ComboUtils.badgeCount(delegateRoot.model)

                    delegate: NIcon {
                      id: badgeIcon
                      required property int index
                      readonly property var badgeData: ComboUtils.badgeData(delegateRoot.model, badgeIcon.index)

                      icon: ComboUtils.badgeIcon(badgeData)
                      pointSize: ComboUtils.badgeSize(badgeData, Style)
                      color: delegateRoot.highlighted ? Color.mOnHover : (ComboUtils.badgeColor(badgeData, Color.mOnSurface))
                      Layout.preferredWidth: Math.round(Style.baseWidgetSize * 0.6)
                      Layout.preferredHeight: Math.round(Style.baseWidgetSize * 0.6)
                      visible: ComboUtils.badgeVisible(badgeData)
                    }
                  }
                }
              }
              background: Rectangle {
                anchors.fill: parent
                color: delegateRoot.highlighted ? Color.mHover : "transparent"
                radius: Style.iRadiusS
              }
            }
          }
        }
      }

      background: Rectangle {
        color: Color.mSurfaceVariant
        border.color: Color.mOutline
        border.width: Style.borderS
        radius: Style.iRadiusM
      }
    }

    // Update the currentIndex if the currentKey is changed externally
    Connections {
      target: root
      function onCurrentKeyChanged() {
        combo.currentIndex = root.findIndexInActiveModel(root.currentKey);
      }
    }

    // Focus search input when popup opens and ensure model is filtered
    Connections {
      target: combo.popup
      function onVisibleChanged() {
        if (combo.popup.visible) {
          // Ensure the model is filtered when popup opens
          root.filterModel();
          listView.currentIndex = Math.max(0, root.findIndexInActiveModel(root.currentKey));
          // Small delay to ensure the popup is fully rendered
          Qt.callLater(() => {
                         if (searchInput && searchInput.inputItem) {
                           ComboUtils.focusItem(searchInput.inputItem);
                         }
                       });
        } else {
          root.searchText = "";
        }
      }
    }
  }
}
