import QtQuick 6.10
import QtQuick.Layouts
import qs.Commons

Rectangle {
  id: root
  objectName: "NTabBar"

  // Public properties
  property int currentIndex: 0
  property real spacing: Style.marginXS
  property real margins: 0
  property real tabHeight: Style.baseWidgetSize
  property bool distributeEvenly: false
  default property alias content: tabRow.children

  onDistributeEvenlyChanged: _applyDistribution()
  Component.onCompleted: _applyDistribution()

  function _updateFirstLast() {
    var child, i;
    // Defensive check for QML initialization timing
    if (!tabRow || !tabRow.children) {
      return;
    }
    var kids = tabRow.children;
    var len = kids.length;
    var firstVisible = -1;
    var lastVisible = -1;
    for (i = 0; i < len; i++) {
      child = kids[i];
      // Only consider items that have isFirst/isLast (actual tab buttons, not Repeaters)
      if (child.visible && "isFirst" in child) {
        if (firstVisible === -1)
          firstVisible = i;
        lastVisible = i;
      }
    }
    for (i = 0; i < len; i++) {
      child = kids[i];
      if ("isFirst" in child)
        child.isFirst = (i === firstVisible);
      if ("isLast" in child)
        child.isLast = (i === lastVisible);
    }
  }

  function _applyDistribution() {
    var child, i;
    if (!tabRow || !tabRow.children) {
      return;
    }
    if (!distributeEvenly) {
      for (i = 0; i < tabRow.children.length; i++) {
        child = tabRow.children[i];
        child.Layout.fillWidth = true;
      }
      return;
    }

    for (i = 0; i < tabRow.children.length; i++) {
      child = tabRow.children[i];
      child.Layout.fillWidth = true;
      child.Layout.preferredWidth = 1;
    }
  }

  // Styling
  Layout.margins: Style.borderS
  implicitWidth: tabRow.implicitWidth + (margins * 2)
  implicitHeight: tabHeight + (margins * 2)
  color: Color.smartAlpha(Color.mSurfaceVariant)
  radius: Style.iRadiusM

  RowLayout {
    id: tabRow
    anchors.fill: parent
    anchors.margins: margins
    spacing: root.spacing

    onChildrenChanged: {
      for (var i = 0; i < children.length; i++) {
        var child = children[i];
        child.visibleChanged.connect(root._updateFirstLast);
      }
      root._updateFirstLast();
      root._applyDistribution();
    }
  }
}
