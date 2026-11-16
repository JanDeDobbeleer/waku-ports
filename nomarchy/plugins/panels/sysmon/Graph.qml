import QtQuick
import QtQuick.Shapes
import "Model.js" as Model

// A load sparkline on a fixed 0-100 scale: a thin line in the foreground
// colour over a faint fill and a hairline baseline.
Item {
  id: graph

  property var history: []
  property int samples: 30
  property color color: "white"
  property real lineWidth: 1

  readonly property var points: Model.sparkPoints(history, samples, width, height, lineWidth)

  Rectangle {
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.bottom: parent.bottom
    height: 1
    color: Qt.rgba(graph.color.r, graph.color.g, graph.color.b, 0.25)
  }

  Shape {
    anchors.fill: parent
    preferredRendererType: Shape.CurveRenderer

    ShapePath {
      strokeWidth: -1
      strokeColor: "transparent"
      fillColor: Qt.rgba(graph.color.r, graph.color.g, graph.color.b, 0.16)
      PathPolyline { path: Model.areaPoints(graph.points, graph.height) }
    }

    ShapePath {
      strokeWidth: graph.lineWidth
      strokeColor: graph.color
      fillColor: "transparent"
      joinStyle: ShapePath.RoundJoin
      capStyle: ShapePath.RoundCap
      PathPolyline { path: graph.points }
    }
  }
}