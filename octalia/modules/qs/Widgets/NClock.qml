pragma ComponentBehavior: Bound

import "NClockUtils.js" as ClockUtils

import QtQuick 6.10
import QtQuick.Layouts
import "../Helpers/ColorsConvert.js" as ColorsConvert
import qs.Commons
import qs.Widgets

Item {
  id: root

  property var now: Time.now

  // Style: "analog" or "digital"
  property string clockStyle: "analog"

  // Show seconds progress ring (digital only)
  property bool showProgress: true

  // Color properties
  property color backgroundColor: Color.mPrimary
  property color clockColor: Color.mOnPrimary

  property color secondHandColor: {
    var candidate, contrastBg, contrastClock, currentWorstContrast, i;
    var defaultColor = Color.mError;
    var bestContrast = 1.0; // 1.0 is "no contrast"
    var bestColor = defaultColor;
    var candidates = [Color.mSecondary, Color.mTertiary, Color.mError];

    const minContrast = 1.149;

    for (i = 0; i < candidates.length; i++) {
      candidate = candidates[i];
      contrastClock = ColorsConvert.getContrastRatio(candidate.toString(), clockColor.toString());
      if (contrastClock < minContrast) {
        continue;
      }
      contrastBg = ColorsConvert.getContrastRatio(candidate.toString(), backgroundColor.toString());
      if (contrastBg < minContrast) {
        continue;
      }

      currentWorstContrast = Math.min(contrastBg, contrastClock);

      if (currentWorstContrast > bestContrast) {
        bestContrast = currentWorstContrast;
        bestColor = candidate;
      }
    }

    return bestColor;
  }

  property color progressColor: root.secondHandColor

  // Font size properties for digital clock
  property real hoursFontSize: Style.fontSizeXS
  property real minutesFontSize: Style.fontSizeXXS
  property int hoursFontWeight: Style.fontWeightBold
  property int minutesFontWeight: Style.fontWeightBold

  // Scale ratio for canvas line widths (used by desktop widget scaling)
  property real scaleRatio: Style.uiScaleRatio

  height: Math.round((Style.fontSizeXXXL * 1.9) / 2 * Style.uiScaleRatio) * 2
  width: root.height

  Loader {
    id: clockLoader
    anchors.fill: parent

    sourceComponent: {
      if (root.clockStyle === "analog")
        return analogClockComponent;
      if (root.clockStyle === "binary")
        return binaryClockComponent;
      return digitalClockComponent;
    }

  }

  // Analog Clock Component
  component NClockAnalog: Item {
    id: analogClock
    property var now
    property color backgroundColor: Color.mPrimary
    property color clockColor: Color.mOnPrimary
    property color secondHandColor: Color.mError
    property real scaleRatio: Style.uiScaleRatio
    anchors.fill: parent

    Canvas {
      id: clockCanvas
      anchors.fill: parent

      Connections {
        target: Time
        function onNowChanged() {
          clockCanvas.requestPaint();
        }
      }

      onPaint: {
        var i, scaleFactor;
        var currentTime = Time.now;
        var hours = currentTime.getHours();
        var minutes = currentTime.getMinutes();
        var seconds = currentTime.getSeconds();

        const markAlpha = 0.7;
        var ctx = getContext("2d");
        ctx.reset();
        ctx.translate(width / 2, height / 2);
        var radius = Math.min(width, height) / 2;

        // Hour marks
        ctx.strokeStyle = Qt.alpha(analogClock.clockColor, markAlpha);
        ctx.lineWidth = 2 * analogClock.scaleRatio;
        var scaleFactor = 0.7;

        for (i = 0; i < 12; i++) {
          scaleFactor = 0.8;
          if (i % 3 === 0) {
            scaleFactor = 0.65;
          }
          ctx.save();
          ctx.rotate(i * Math.PI / 6);
          ctx.beginPath();
          ctx.moveTo(0, -radius * scaleFactor);
          ctx.lineTo(0, -radius);
          ctx.stroke();
          ctx.restore();
        }

        // Hour hand
        ctx.save();
        var hourAngle = (hours % 12 + minutes / 60) * Math.PI / 6;
        ctx.rotate(hourAngle);
        ctx.strokeStyle = analogClock.clockColor;
        ctx.lineWidth = 3 * analogClock.scaleRatio;
        ctx.lineCap = "round";
        ctx.beginPath();
        ctx.moveTo(0, 0);
        ctx.lineTo(0, -radius * 0.6);
        ctx.stroke();
        ctx.restore();

        // Minute hand
        ctx.save();
        var minuteAngle = (minutes + seconds / 60) * Math.PI / 30;
        ctx.rotate(minuteAngle);
        ctx.strokeStyle = analogClock.clockColor;
        ctx.lineWidth = 2 * analogClock.scaleRatio;
        ctx.lineCap = "round";
        ctx.beginPath();
        ctx.moveTo(0, 0);
        ctx.lineTo(0, -radius * 0.9);
        ctx.stroke();
        ctx.restore();

        // Second hand
        ctx.save();
        var secondAngle = seconds * Math.PI / 30;
        ctx.rotate(secondAngle);
        ctx.strokeStyle = analogClock.secondHandColor;
        ctx.lineWidth = 1.6 * analogClock.scaleRatio;
        ctx.lineCap = "round";
        ctx.beginPath();
        ctx.moveTo(0, 0);
        ctx.lineTo(0, -radius);
        ctx.stroke();
        ctx.restore();

        // Center dot
        ctx.beginPath();
        ctx.arc(0, 0, 3 * analogClock.scaleRatio, 0, 2 * Math.PI);
        ctx.fillStyle = analogClock.clockColor;
        ctx.fill();
      }

      Component.onCompleted: requestPaint()
    }
  }

  // Digital Clock Component
  component NClockDigital: Item {
    id: digitalClock
    property var now
    property color backgroundColor: Color.mPrimary
    property color clockColor: Color.mOnPrimary
    property color progressColor: Color.mError
    property real hoursFontSize: Style.fontSizeXS
    property real minutesFontSize: Style.fontSizeXXS
    property int hoursFontWeight: Style.fontWeightBold
    property int minutesFontWeight: Style.fontWeightBold
    property real scaleRatio: Style.uiScaleRatio
    property bool showProgress: true

    anchors.fill: parent

    // Digital clock's seconds circular progress
    Canvas {
      id: secondsProgress
      anchors.fill: parent
      visible: digitalClock.showProgress
      property real progress: digitalClock.now.getSeconds() / 60
      onProgressChanged: requestPaint()
      Connections {
        target: Time
        function onNowChanged() {
          const total = digitalClock.now.getSeconds() * 1000 + digitalClock.now.getMilliseconds();
          secondsProgress.progress = total / 60000;
        }
      }
      onPaint: {
        var ctx = getContext("2d");
        var centerX = width / 2;
        var centerY = height / 2;
        var radius = Math.min(width, height) / 2 - 3 * digitalClock.scaleRatio;
        ctx.reset();

        // Background circle
        ctx.beginPath();
        ctx.arc(centerX, centerY, radius, 0, 2 * Math.PI);
        ctx.lineWidth = 2.5 * digitalClock.scaleRatio;
        ctx.strokeStyle = Qt.alpha(digitalClock.clockColor, 0.15);
        ctx.stroke();

        // Progress arc
        ctx.beginPath();
        ctx.arc(centerX, centerY, radius, -Math.PI / 2, -Math.PI / 2 + progress * 2 * Math.PI);
        ctx.lineWidth = 2.5 * digitalClock.scaleRatio;
        ctx.strokeStyle = digitalClock.progressColor;
        ctx.lineCap = "round";
        ctx.stroke();
      }
    }

    // Digital clock
    ColumnLayout {
      anchors.centerIn: parent
      spacing: -Style.marginXXS

      NText {
        text: {
          var t = Settings.data.location.use12hourFormat ? I18n.locale.toString(digitalClock.now, "hh AP") : I18n.locale.toString(digitalClock.now, "HH");
          return t.split(" ")[0];
        }

        pointSize: digitalClock.hoursFontSize
        font.weight: digitalClock.hoursFontWeight
        color: digitalClock.clockColor
        family: Settings.data.ui.fontFixed
        Layout.alignment: Qt.AlignHCenter
      }

      NText {
        text: ClockUtils.minutes(digitalClock.now)
        pointSize: digitalClock.minutesFontSize
        font.weight: digitalClock.minutesFontWeight
        color: digitalClock.clockColor
        family: Settings.data.ui.fontFixed
        Layout.alignment: Qt.AlignHCenter
      }
    }
  }

  // Binary Clock Component
  component NClockBinary: Item {
    id: binaryClock
    property var now
    property color backgroundColor
    property color clockColor: Color.mOnPrimary

    anchors.fill: parent

    readonly property int h: now.getHours()
    readonly property int m: now.getMinutes()
    readonly property int s: now.getSeconds()

    // BCD (Binary Coded Decimal) Format:
    // H1 H2 : M1 M2 : S1 S2
    // H1 (tens): 0-2 (2 bits)
    // H2 (ones): 0-9 (4 bits)
    // M1 (tens): 0-5 (3 bits)
    // M2 (ones): 0-9 (4 bits)
    // S1 (tens): 0-5 (3 bits)
    // S2 (ones): 0-9 (4 bits)

    RowLayout {
      anchors.centerIn: parent
      spacing: parent.width * 0.05

      // Hours
      RowLayout {
        spacing: parent.parent.width * 0.02
        BinaryColumn {
          value: Math.floor(binaryClock.h / 10)
          bits: 2
          dotSize: root.width * 0.08
          activeColor: binaryClock.clockColor
          Layout.alignment: Qt.AlignBottom
        }
        BinaryColumn {
          value: binaryClock.h % 10
          bits: 4
          dotSize: root.width * 0.08
          activeColor: binaryClock.clockColor
          Layout.alignment: Qt.AlignBottom
        }
      }

      // Minutes
      RowLayout {
        spacing: parent.parent.width * 0.02
        BinaryColumn {
          value: Math.floor(binaryClock.m / 10)
          bits: 3
          dotSize: root.width * 0.08
          activeColor: binaryClock.clockColor
          Layout.alignment: Qt.AlignBottom
        }
        BinaryColumn {
          value: binaryClock.m % 10
          bits: 4
          dotSize: root.width * 0.08
          activeColor: binaryClock.clockColor
          Layout.alignment: Qt.AlignBottom
        }
      }

      // Seconds
      RowLayout {
        spacing: parent.parent.width * 0.02
        BinaryColumn {
          value: Math.floor(binaryClock.s / 10)
          bits: 3
          dotSize: root.width * 0.08
          activeColor: binaryClock.clockColor
          Layout.alignment: Qt.AlignBottom
        }
        BinaryColumn {
          value: binaryClock.s % 10
          bits: 4
          dotSize: root.width * 0.08
          activeColor: binaryClock.clockColor
          Layout.alignment: Qt.AlignBottom
        }
      }
    }
  }

  component BinaryColumn: Column {
    id: binaryColumn
    property int value: 0
    property int bits: 4
    property real dotSize: 10
    property color activeColor: "white"

    spacing: dotSize * 0.4

    Repeater {
      model: binaryColumn.bits

      Rectangle {
        id: binaryDot
        required property int index
        property int bitIndex: (binaryColumn.bits - 1) - binaryDot.index
        property bool isActive: (binaryColumn.value >> bitIndex) & 1

        width: binaryColumn.dotSize
        height: binaryColumn.dotSize
        radius: binaryColumn.dotSize / 2
        color: isActive ? binaryColumn.activeColor : Qt.alpha(binaryColumn.activeColor, 0.2)

        Behavior on color {
          ColorAnimation {
            duration: 200
          }
        }
      }
    }
  }

  Component {
    id: analogClockComponent
    NClockAnalog {
      now: root.now
      backgroundColor: root.backgroundColor
      clockColor: root.clockColor
      secondHandColor: root.secondHandColor
      scaleRatio: root.scaleRatio
    }
  }

  Component {
    id: digitalClockComponent
    NClockDigital {
      now: root.now
      backgroundColor: root.backgroundColor
      clockColor: root.clockColor
      progressColor: root.progressColor
      hoursFontSize: root.hoursFontSize
      minutesFontSize: root.minutesFontSize
      hoursFontWeight: root.hoursFontWeight
      minutesFontWeight: root.minutesFontWeight
      scaleRatio: root.scaleRatio
      showProgress: root.showProgress
    }
  }

  Component {
    id: binaryClockComponent
    NClockBinary {
      now: root.now
      backgroundColor: root.backgroundColor
      clockColor: root.clockColor
    }
  }
}
