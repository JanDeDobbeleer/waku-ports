import QtQuick 6.10
import QtQuick.Controls.Basic
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

ColumnLayout {
  id: root
  spacing: 0

  NTabView {
    id: tabView
    currentIndex: 0

    VersionSubTab {}
  }
}
