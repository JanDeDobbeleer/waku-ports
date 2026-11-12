pragma ComponentBehavior: Bound

import QtQuick 6.10
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

NCollapsible {
  id: root

  // Public API
  property var tags: []  // Array of tag strings
  property string selectedTag: ""

  // Formatting function for tag display (optional override)
  property var formatTag: function (tag) {
    if (tag === "")
      return I18n.tr("launcher.categories.all");
    // Default: capitalize first letter
    return tag.charAt(0).toUpperCase() + tag.slice(1);
  }

  Layout.fillWidth: true
  contentSpacing: Style.marginXS

  Flow {
    Layout.fillWidth: true
    spacing: Style.marginXS
    flow: Flow.LeftToRight

    Repeater {
      model: [""].concat(root.tags)

      delegate: NButton {
        id: tagButton
        required property string modelData
        text: root.formatTag(tagButton.modelData)
        backgroundColor: root.selectedTag === tagButton.modelData ? Color.mPrimary : Color.mSurfaceVariant
        textColor: root.selectedTag === tagButton.modelData ? Color.mOnPrimary : Color.mOnSurfaceVariant
        onClicked: root.selectedTag = tagButton.modelData
        fontSize: Style.fontSizeS
        iconSize: Style.fontSizeS
        fontWeight: Style.fontWeightSemiBold
        buttonRadius: Style.iRadiusM
      }
    }
  }
}
