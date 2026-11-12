import QtQuick 6.10
import QtQuick.Controls.Basic
import QtQuick.Layouts
import qs.Commons
import qs.Services.Keyboard
import qs.Widgets
import "./ClipboardPreviewUtils.js" as ClipboardPreviewUtils

Item {
  id: previewPanel

  property var currentItem: null
  property string fullContent: ""
  property string imageDataUrl: ""
  property bool loadingFullContent: false
  property bool isImageContent: false

  implicitHeight: contentArea.implicitHeight + Style.margin2L

  function loadContent(): void {
    ClipboardPreviewUtils.loadContent(previewPanel, ClipboardService);
  }

  Connections {
    target: previewPanel
    function onCurrentItemChanged(): void {
      previewPanel.fullContent = "";
      previewPanel.imageDataUrl = "";
      previewPanel.loadingFullContent = false;
      previewPanel.isImageContent = ClipboardPreviewUtils.field(previewPanel.currentItem, "isImage");

      if (ClipboardPreviewUtils.field(previewPanel.currentItem, "clipboardId")) {
        previewPanel.loadContent();
      }
    }
  }

  readonly property int _rev: ClipboardService.revision
  on_RevChanged: {
    // When cache updates, try to load content if we're still showing loading or preview
    ClipboardPreviewUtils.refreshCachedText(previewPanel, ClipboardService);
  }

  Timer {
    id: imageUpdateTimer
    interval: 200
    running: ClipboardPreviewUtils.shouldUpdateImage(previewPanel)
    repeat: ClipboardPreviewUtils.shouldUpdateImage(previewPanel)

    onTriggered: {
      ClipboardPreviewUtils.updateImage(previewPanel, ClipboardService);
    }
  }

  Item {
    id: contentArea
    anchors.fill: parent
    anchors.margins: Style.marginS

    BusyIndicator {
      anchors.centerIn: parent
      running: previewPanel.loadingFullContent
      visible: previewPanel.loadingFullContent
      width: Style.baseWidgetSize
      height: width
    }

    // Preview for image entry
    ColumnLayout {
      anchors.fill: parent
      anchors.margins: Style.marginS
      spacing: Style.marginS
      visible: previewPanel.isImageContent && !previewPanel.loadingFullContent && previewPanel.imageDataUrl !== ""

      NImageRounded {
        id: previewImage
        Layout.fillWidth: true
        Layout.fillHeight: true
        radius: Style.marginS
        imagePath: previewPanel.imageDataUrl
        imageFillMode: Image.PreserveAspectFit
      }

      NDivider {
        Layout.fillWidth: true
        Layout.bottomMargin: Style.marginS
      }

      NText {
        Layout.fillWidth: true
        text: {
          const meta = ClipboardService.parseImageMeta(ClipboardPreviewUtils.field(previewPanel.currentItem, "preview"));
          if (meta)
            return ClipboardPreviewUtils.formatImageMeta(meta);
          // Fallback to basic info
          const format = ClipboardPreviewUtils.imageFormat(ClipboardPreviewUtils.field(previewPanel.currentItem, "mime")) || "Image";
          return `${format} • ${previewImage.implicitWidth}×${previewImage.implicitHeight}`;
        }
        pointSize: Style.fontSizeS
        color: Color.mOnSurfaceVariant
      }
    }

    // Preview for text entry
    ColumnLayout {
      anchors.fill: parent
      anchors.margins: Style.marginS
      spacing: Style.marginS
      visible: !previewPanel.isImageContent && !previewPanel.loadingFullContent

      NScrollView {
        id: clipboardScrollView
        Layout.fillWidth: true
        Layout.fillHeight: true
        horizontalPolicy: Settings.data.appLauncher.clipboardWrapText ? ScrollBar.AlwaysOff : ScrollBar.AsNeeded

        NText {
          text: previewPanel.fullContent
          width: Settings.data.appLauncher.clipboardWrapText ? clipboardScrollView.availableWidth : implicitWidth
          wrapMode: Settings.data.appLauncher.clipboardWrapText ? Text.Wrap : Text.NoWrap
          textFormat: Text.PlainText
          font.pointSize: Style.fontSizeM
          font.family: Settings.data.ui.fontFixed
          color: Color.mOnSurface
        }
      }

      NDivider {
        Layout.fillWidth: true
        Layout.bottomMargin: Style.marginS
      }

      NText {
        Layout.fillWidth: true
        visible: previewPanel.fullContent.length > 0
        text: ClipboardPreviewUtils.contentStats(previewPanel.fullContent)
        pointSize: Style.fontSizeS
        color: Color.mOnSurfaceVariant
      }
    }
  }
}
