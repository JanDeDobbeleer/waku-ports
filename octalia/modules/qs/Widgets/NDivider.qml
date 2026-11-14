import QtQuick 6.10
import qs.Commons

Rectangle {
  id: root

  property bool vertical: false

  width: vertical ? Style.borderS : parent.width
  height: vertical ? parent.height : Style.borderS
  gradient: Gradient {
    orientation: root.vertical ? Gradient.Vertical : Gradient.Horizontal
    GradientStop {
      position: 0.0
      color: "transparent"
    }
    GradientStop {
      position: 0.1
      color: Color.mOutline
    }
    GradientStop {
      position: 0.9
      color: Color.mOutline
    }
    GradientStop {
      position: 1.0
      color: "transparent"
    }
  }
}
