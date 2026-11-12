import QtQuick 6.10
import QtQuick.Layouts
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
