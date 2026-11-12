pragma ComponentBehavior: Bound

import "SpectrumWidgetUtils.js" as SpectrumWidgetUtils

import QtQuick 6.10
import qs.Commons

Item {
  id: root
  property color fillColor: Color.mPrimary
  property color strokeColor: Color.mOnSurface
  property int strokeWidth: 0
  property var values: []
  property bool vertical: false
  property bool mirrored: true

  // Minimum signal properties
  property bool showMinimumSignal: false
  property real minimumSignalValue: 0.01 // Default to 1% of height

  // Pre-compute mirroring
  readonly property int valuesCount: SpectrumWidgetUtils.length(values)
  readonly property int totalBars: mirrored ? valuesCount * 2 : valuesCount
  readonly property real barSlotSize: totalBars > 0 ? (vertical ? height : width) / totalBars : 0
  readonly property bool highQuality: (Settings.data.audio.visualizerType === "low") ? false : true
  readonly property real centerY: height / 2
  readonly property real centerX: width / 2

  Repeater {
    model: root.totalBars

    Rectangle {
      id: spectrumBar
      required property int index
      property int valueIndex: root.mirrored ? (spectrumBar.index < root.valuesCount ? root.valuesCount - 1 - index : spectrumBar.index - root.valuesCount) : spectrumBar.index

      property real rawAmp: (root.values && root.values[valueIndex] !== undefined) ? root.values[valueIndex] : 0
      property real amp: (root.showMinimumSignal && rawAmp === 0) ? root.minimumSignalValue : rawAmp

      property real barSize: (root.vertical ? root.width : root.height) * amp

      color: root.fillColor
      border.color: root.strokeColor
      border.width: root.strokeWidth
      antialiasing: root.highQuality
      smooth: root.highQuality

      width: root.vertical ? barSize : root.barSlotSize * 0.8
      height: root.vertical ? root.barSlotSize * 0.8 : barSize
      x: root.vertical ? root.centerX - (barSize / 2) : spectrumBar.index * root.barSlotSize + (root.barSlotSize * 0.25)
      y: root.vertical ? spectrumBar.index * root.barSlotSize + (root.barSlotSize * 0.25) : root.centerY - (barSize / 2)

      // Disable updates when invisible to save GPU
      visible: root.visible
    }
  }
}
