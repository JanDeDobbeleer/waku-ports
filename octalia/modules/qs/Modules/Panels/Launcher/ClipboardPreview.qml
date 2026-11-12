import QtQuick 6.10
import QtQuick.Controls.Basic
import QtQuick.Layouts
import qs.Commons
import qs.Services.Keyboard
import qs.Widgets

Item {
  id: previewPanel

  property var currentItem: null
  property string fullContent: ""
  property string imageDataUrl: ""
  property bool loadingFullContent: false
  property bool isImageContent: false

  implicitHeight: contentArea.implicitHeight + Style.margin2L

  function loadContent() {
    var requestedId;
    if (!currentItem || !currentItem.clipboardId)
      return;

    if (isImageContent) {
      // For images, check cache first then decode
      imageDataUrl = ClipboardService.getImageData(currentItem.clipboardId) || "";
      loadingFullContent = !imageDataUrl;
      if (!imageDataUrl && currentItem.mime) {
        ClipboardService.decodeToDataUrl(currentItem.clipboardId, currentItem.mime, null);
      }
    } else {
      // For text, check sync cache first
      const cached = ClipboardService.getContent(currentItem.clipboardId);
      if (cached) {
        fullContent = cached;
        loadingFullContent = false;
      } else {
        // Show preview while loading full content
        fullContent = currentItem.preview || "";
        loadingFullContent = true;
        // Async decode as fallback
        requestedId = currentItem.clipboardId;
        ClipboardService.decode(requestedId, function (content) {
          var trimmed;
          if (!previewPanel || !previewPanel.currentItem) {
            return;
          }
          if (previewPanel.currentItem.clipboardId === requestedId) {
            trimmed = content ? content.trim() : "";
            if (trimmed !== "") {
              previewPanel.fullContent = trimmed;
            }
            previewPanel.loadingFullContent = false;
          }
        });
      }
    }
  }

  Connections {
    target: previewPanel
    function onCurrentItemChanged() {
      previewPanel.fullContent = "";
      previewPanel.imageDataUrl = "";
      previewPanel.loadingFullContent = false;
      previewPanel.isImageContent = previewPanel.currentItem && previewPanel.currentItem.isImage;

      if (previewPanel.currentItem && previewPanel.currentItem.clipboardId) {
        loadContent();
      }
    }
  }

  readonly property int _rev: ClipboardService.revision
  on_RevChanged: {
    // When cache updates, try to load content if we're still showing loading or preview
    if (currentItem && currentItem.clipboardId && !isImageContent && loadingFullContent) {
      const cached = ClipboardService.getContent(currentItem.clipboardId);
      if (cached) {
        fullContent = cached;
        loadingFullContent = false;
      }
    }
  }

  Timer {
    id: imageUpdateTimer
    interval: 200
    running: previewPanel.currentItem && previewPanel.currentItem.isImage && previewPanel.imageDataUrl === ""
    repeat: previewPanel.currentItem && previewPanel.currentItem.isImage && previewPanel.imageDataUrl === ""

    onTriggered: {
      if (previewPanel.currentItem && previewPanel.currentItem.clipboardId) {
        const newData = ClipboardService.getImageData(previewPanel.currentItem.clipboardId) || "";
        if (newData !== previewPanel.imageDataUrl) {
          previewPanel.imageDataUrl = newData;
          if (newData) {
            previewPanel.loadingFullContent = false;
          }
        }
      }
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
          const meta = ClipboardService.parseImageMeta(previewPanel.currentItem?.preview);
          if (meta)
            return `${meta.fmt} • ${meta.w}×${meta.h} • ${meta.size}`;
          // Fallback to basic info
          const format = (previewPanel.currentItem?.mime || "image").split("/")[1]?.toUpperCase() || "Image";
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
        text: {
          const chars = previewPanel.fullContent.length;
          const words = previewPanel.fullContent.split(/\s+/).filter(w => w.length > 0).length;
          const lines = previewPanel.fullContent.split('\n').length;
          return `${chars} chars, ${words} words, ${lines} lines`;
        }
        pointSize: Style.fontSizeS
        color: Color.mOnSurfaceVariant
      }
    }
  }
}
