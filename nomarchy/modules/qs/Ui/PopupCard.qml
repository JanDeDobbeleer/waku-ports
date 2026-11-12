import QtQuick
import Quickshell
import Quickshell.Hyprland
import qs.Commons
import qs.Commons as Commons
import "BarValues.js" as BarValues

PopupWindow {
  id: root

  required property Item anchorItem
  required property QtObject hostBar
  property var owner: null
  property int edgeMargin: Style.gapsOut
  property int padding: Style.spacing.popupPadding
  property int cardWidth: Style.space(280)
  property int cardHeight: Style.space(200)
  property color borderColor: Commons.Color.popups.border
  property var borderSpec: Border.localOrSurfaceSpec("popups", "border", borderColor, Commons.Color.popups.border, Math.max(1, Style.space(2)))
  property bool open: false
  property bool centerOnBar: false
  // "click" — uses HyprlandFocusGrab so clicking outside dismisses the popup.
  // "hover" — passive overlay; the owning widget controls open via hover.
  property string triggerMode: "click"

  readonly property var coordinatorKey: owner || root
  readonly property var anchorWindow: anchorItem ? anchorItem.QsWindow.window : null
  readonly property var popupScreen: anchorWindow ? anchorWindow.screen : null
  readonly property bool containsMouse: cardHover.hovered
  readonly property real screenW: popupScreen ? popupScreen.width : 0
  readonly property real screenH: popupScreen ? popupScreen.height : 0
  // Thickness of the painted bar strip on this screen, notch floor
  // included. The bar window spans its whole screen (only the strip inside
  // it is painted and takes input), so the window's dimensions say nothing
  // about the bar.
  readonly property real barThickness: !hostBar ? 0
    : BarValues.sizeForScreen(hostBar, popupScreen)
  readonly property real availableCardWidth: screenW > 0
    ? Math.max(120, screenW - ((hostBar && (BarValues.position(hostBar) === "left" || BarValues.position(hostBar) === "right")) ? barThickness : 0) - root.edgeMargin * 2)
    : 0
  readonly property real availableCardHeight: screenH > 0
    ? Math.max(120, screenH - ((hostBar && (BarValues.position(hostBar) === "top" || BarValues.position(hostBar) === "bottom")) ? barThickness : 0) - root.edgeMargin * 2)
    : 0
  readonly property real verticalContentInset: padding * 2 + Border.top(borderSpec) + Border.bottom(borderSpec)

  function fittedContentWidth(width, cap): real {
    var desired = Math.max(1, Number(width) || 1)
    var maxWidth = root.availableCardWidth > 0 ? root.availableCardWidth : desired
    if (cap !== undefined && Number(cap) > 0) maxWidth = Math.min(maxWidth, Number(cap))
    return Math.round(Math.min(desired, maxWidth))
  }

  function fittedContentHeight(implicitHeight, cap): real {
    var desired = Math.max(root.verticalContentInset, (Number(implicitHeight) || 0) + root.verticalContentInset)
    var maxHeight = root.availableCardHeight > 0 ? root.availableCardHeight : desired
    if (cap !== undefined && Number(cap) > 0) maxHeight = Math.min(maxHeight, Number(cap))
    return Math.round(Math.min(desired, maxHeight))
  }

  function cappedContentHeight(height: var): real {
    var desired = Math.max(root.padding * 2, Number(height) || root.padding * 2)
    var maxHeight = root.availableCardHeight > 0 ? root.availableCardHeight : desired
    return Math.round(Math.min(desired, maxHeight))
  }

  function close() {
    if (owner && "close" in owner) owner.close()
    else root.open = false
  }

  default property alias cardContent: contentHolder.children

  visible: open || card.opacity > 0
  color: "transparent"
  // A closing card stays mapped until its fade ends; it must not take clicks
  // meant for the bar underneath while it does.
  implicitWidth: cardWidth
  implicitHeight: cardHeight


  onOpenChanged: {
    if (!hostBar) return
    if (open) BarValues.requestPopout(hostBar, coordinatorKey)
    else if (BarValues.activePopout(hostBar) === coordinatorKey) BarValues.releasePopout(hostBar, coordinatorKey)
  }

  // Outside-click dismissal via Hyprland's focus grab. While `active`, input
  // is routed only to the listed windows; clicking anywhere else clears the
  // grab and we close the popup. Skipped for hover-mode popups so the cursor
  // can move freely between the trigger and the popup.
  HyprlandFocusGrab {
    active: root.open && root.triggerMode === "click"
    windows: root.anchorWindow ? [root, root.anchorWindow] : [root]
    onCleared: root.close()
  }

  anchor {
    item: root.anchorItem
  }

  BorderSurface {
    id: card
    anchors.fill: parent
    color: Commons.Color.popups.background
    borderSpec: root.borderSpec
    padding: root.padding
    radius: Style.cornerRadius

    // Grows out of the bar from just under full size as it fades in, as the
    // keyboard panels do, and goes in two thirds of the time.
    property real shown: root.open ? 1 : 0
    Behavior on shown {
      id: showing
      NumberAnimation {
        duration: Style.duration(showing.targetValue > 0 ? 180 : 120)
        easing.type: Easing.Bezier
        easing.bezierCurve: Style.easeOut
      }
    }
    opacity: shown
    scale: 0.97 + 0.03 * shown
    transformOrigin: !root.hostBar || BarValues.position(root.hostBar) === "top" ? Item.Top
      : BarValues.position(root.hostBar) === "bottom" ? Item.Bottom
      : BarValues.position(root.hostBar) === "left" ? Item.Left : Item.Right

    Item {
      id: contentHolder
      anchors.fill: parent
      // Right-to-left languages read the card mirrored; the card itself
      // stays where the bar puts it.
      LayoutMirroring.enabled: Commons.I18n.rightToLeft
      LayoutMirroring.childrenInherit: true
      anchors.topMargin: card.contentTopInset
      anchors.rightMargin: card.contentRightInset
      anchors.bottomMargin: card.contentBottomInset
      anchors.leftMargin: card.contentLeftInset
    }

    HoverHandler {
      id: cardHover
    }
  }
}
