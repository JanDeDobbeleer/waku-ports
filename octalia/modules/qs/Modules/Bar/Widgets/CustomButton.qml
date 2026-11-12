import QtQuick 6.10
import Quickshell
import Quickshell.Io
import qs.Commons
import "../BarWidgetHelpers.js" as BarWidgetHelpers
import qs.Modules.Bar.Extras
import qs.Services.Control
import qs.Services.UI
import qs.Widgets

Item {
  id: root

  NPopupContextMenu {
    id: contextMenu

    model: [
      {
        "label": I18n.tr("actions.widget-settings"),
        "action": "widget-settings",
        "icon": "settings"
      },
    ]

    onTriggered: action => {
                   contextMenu.close();
                   PanelService.closeContextMenu(screen);

                   if (action === "widget-settings") {
                     BarService.openWidgetSettings(screen, section, sectionWidgetIndex, widgetId, widgetSettings);
                   }
                 }
  }

  property ShellScreen screen

  // Widget properties passed from Bar.qml for per-instance settings
  property string widgetId: ""
  property string section: ""
  property int sectionWidgetIndex: -1
  property int sectionWidgetsCount: 0

  property var widgetMetadata: BarWidgetRegistry.widgetMetadata[widgetId] ?? {}
  // Explicit screenName property ensures reactive binding when screen changes
  readonly property string screenName: screen ? screen.name : ""
  property var widgetSettings: {
    var widgets;
    if (section && sectionWidgetIndex >= 0 && screenName) {
      widgets = Settings.getBarWidgetsForScreen(screenName)[section];
      if (widgets && sectionWidgetIndex < widgets.length) {
        return widgets[sectionWidgetIndex];
      }
    }
    return {};
  }

  readonly property string barPosition: Settings.getBarPositionForScreen(screenName)
  readonly property bool isVerticalBar: barPosition === "left" || barPosition === "right"

  readonly property string customIcon: BarWidgetHelpers.readProperty(widgetSettings, "icon") || BarWidgetHelpers.readProperty(widgetMetadata, "icon")
  readonly property string iconPosition: BarWidgetHelpers.readProperty(widgetSettings, "iconPosition") || BarWidgetHelpers.readProperty(widgetMetadata, "iconPosition")
  readonly property string leftClickExec: BarWidgetHelpers.readProperty(widgetSettings, "leftClickExec") || BarWidgetHelpers.readProperty(widgetMetadata, "leftClickExec")
  readonly property bool leftClickUpdateText: BarWidgetHelpers.readProperty(widgetSettings, "leftClickUpdateText") ?? BarWidgetHelpers.readProperty(widgetMetadata, "leftClickUpdateText")
  readonly property string rightClickExec: BarWidgetHelpers.readProperty(widgetSettings, "rightClickExec") || BarWidgetHelpers.readProperty(widgetMetadata, "rightClickExec")
  readonly property bool rightClickUpdateText: BarWidgetHelpers.readProperty(widgetSettings, "rightClickUpdateText") ?? BarWidgetHelpers.readProperty(widgetMetadata, "rightClickUpdateText")
  readonly property string middleClickExec: BarWidgetHelpers.readProperty(widgetSettings, "middleClickExec") || BarWidgetHelpers.readProperty(widgetMetadata, "middleClickExec")
  readonly property bool middleClickUpdateText: BarWidgetHelpers.readProperty(widgetSettings, "middleClickUpdateText") ?? BarWidgetHelpers.readProperty(widgetMetadata, "middleClickUpdateText")
  readonly property string ipcIdentifier: BarWidgetHelpers.readProperty(widgetSettings, "ipcIdentifier") !== undefined ? BarWidgetHelpers.readProperty(widgetSettings, "ipcIdentifier") : (BarWidgetHelpers.readProperty(widgetMetadata, "ipcIdentifier") || "")
  readonly property string wheelExec: BarWidgetHelpers.readProperty(widgetSettings, "wheelExec") || BarWidgetHelpers.readProperty(widgetMetadata, "wheelExec")
  readonly property string wheelUpExec: BarWidgetHelpers.readProperty(widgetSettings, "wheelUpExec") || BarWidgetHelpers.readProperty(widgetMetadata, "wheelUpExec")
  readonly property string wheelDownExec: BarWidgetHelpers.readProperty(widgetSettings, "wheelDownExec") || BarWidgetHelpers.readProperty(widgetMetadata, "wheelDownExec")
  readonly property string wheelMode: BarWidgetHelpers.readProperty(widgetSettings, "wheelMode") || BarWidgetHelpers.readProperty(widgetMetadata, "wheelMode")
  readonly property bool wheelUpdateText: BarWidgetHelpers.readProperty(widgetSettings, "wheelUpdateText") ?? BarWidgetHelpers.readProperty(widgetMetadata, "wheelUpdateText")
  readonly property bool wheelUpUpdateText: BarWidgetHelpers.readProperty(widgetSettings, "wheelUpUpdateText") ?? BarWidgetHelpers.readProperty(widgetMetadata, "wheelUpUpdateText")
  readonly property bool wheelDownUpdateText: BarWidgetHelpers.readProperty(widgetSettings, "wheelDownUpdateText") ?? BarWidgetHelpers.readProperty(widgetMetadata, "wheelDownUpdateText")
  readonly property string textCommand: BarWidgetHelpers.readProperty(widgetSettings, "textCommand") !== undefined ? BarWidgetHelpers.readProperty(widgetSettings, "textCommand") : (BarWidgetHelpers.readProperty(widgetMetadata, "textCommand") || "")
  readonly property bool textStream: BarWidgetHelpers.readProperty(widgetSettings, "textStream") !== undefined ? BarWidgetHelpers.readProperty(widgetSettings, "textStream") : (BarWidgetHelpers.readProperty(widgetMetadata, "textStream") || false)
  readonly property int textIntervalMs: BarWidgetHelpers.readProperty(widgetSettings, "textIntervalMs") !== undefined ? BarWidgetHelpers.readProperty(widgetSettings, "textIntervalMs") : (BarWidgetHelpers.readProperty(widgetMetadata, "textIntervalMs") || 3000)
  readonly property string textCollapse: BarWidgetHelpers.readProperty(widgetSettings, "textCollapse") !== undefined ? BarWidgetHelpers.readProperty(widgetSettings, "textCollapse") : (BarWidgetHelpers.readProperty(widgetMetadata, "textCollapse") || "")
  readonly property bool parseJson: BarWidgetHelpers.readProperty(widgetSettings, "parseJson") !== undefined ? BarWidgetHelpers.readProperty(widgetSettings, "parseJson") : (BarWidgetHelpers.readProperty(widgetMetadata, "parseJson") || false)
  readonly property bool hasExec: (leftClickExec || rightClickExec || middleClickExec || (wheelMode === "unified" && wheelExec) || (wheelMode === "separate" && (wheelUpExec || wheelDownExec)))
  readonly property bool showIcon: (BarWidgetHelpers.readProperty(widgetSettings, "showIcon") !== undefined) ? BarWidgetHelpers.readProperty(widgetSettings, "showIcon") : true
  readonly property string hideMode: BarWidgetHelpers.readProperty(widgetSettings, "hideMode") || "alwaysExpanded"
  readonly property bool hasOutput: _dynamicText !== ""
  readonly property bool shouldForceOpen: textStream && (hideMode === "alwaysExpanded" || hideMode === "maxTransparent")

  readonly property bool _useNewHideLogic: textCommand && textCommand.length > 0 && textStream
  readonly property bool _useTextCommandLogic: textCommand && textCommand.length > 0 && textStream

  readonly property bool _pillVisible: {
    if (!_useTextCommandLogic) {
      return true;
    }
    if (hideMode === "alwaysExpanded" || hideMode === "maxTransparent") {
      return true;
    }
    var hasActualIcon = (_dynamicIcon !== "" || customIcon !== "");
    return hasOutput || (showIcon && hasActualIcon);
  }

  readonly property real _pillOpacity: {
    if (!_useTextCommandLogic) {
      return 1.0;
    }
    if (hideMode === "maxTransparent" && !hasOutput) {
      return 0.0;
    }
    return 1.0;
  }

  readonly property bool _pillForceOpen: {
    if (!_useTextCommandLogic) {
      return _dynamicText !== "" || (textStream && currentMaxTextLength > 0);
    }
    if (currentMaxTextLength <= 0) {
      return false;
    }

    if (hideMode === "alwaysExpanded" || hideMode === "maxTransparent") {
      return true;
    }
    return hasOutput;
  }

  readonly property string _pillIcon: {
    if (!_useTextCommandLogic) {
      if (textCommand && textCommand.length > 0 && showIcon) {
        return _dynamicIcon !== "" ? _dynamicIcon : customIcon;
      } else if (!(textCommand && textCommand.length > 0)) {
        return _dynamicIcon !== "" ? _dynamicIcon : customIcon;
      } else {
        return "";
      }
    }
    if (!showIcon)
      return "";
    var actualIcon = _dynamicIcon !== "" ? _dynamicIcon : customIcon;
    if (hideMode === "expandWithOutput" && actualIcon === "") {
      return "question-mark";
    }
    return actualIcon;
  }

  readonly property string _pillText: {
    if (!_useTextCommandLogic) {
      return (!isVerticalBar || currentMaxTextLength > 0) ? _dynamicText : "";
    }
    if (currentMaxTextLength <= 0) {
      return "";
    }
    if (hasOutput) {
      return _dynamicText;
    }
    if (hideMode === "expandWithOutput") {
      return "";
    }
    return " ".repeat(currentMaxTextLength);
  }

  readonly property string colorizeSystemIcon: {
    if (BarWidgetHelpers.readProperty(widgetSettings, "colorizeSystemIcon") !== undefined)
      return BarWidgetHelpers.readProperty(widgetSettings, "colorizeSystemIcon");
    return BarWidgetHelpers.readProperty(widgetMetadata, "colorizeSystemIcon") !== undefined ? BarWidgetHelpers.readProperty(widgetMetadata, "colorizeSystemIcon") : "none";
  }
  readonly property string colorizeSystemText: {
    if (BarWidgetHelpers.readProperty(widgetSettings, "colorizeSystemText") !== undefined)
      return BarWidgetHelpers.readProperty(widgetSettings, "colorizeSystemText");
    return BarWidgetHelpers.readProperty(widgetMetadata, "colorizeSystemText") !== undefined ? BarWidgetHelpers.readProperty(widgetMetadata, "colorizeSystemText") : "none";
  }

  // Colorization is active if either icon or text has a color set
  readonly property bool isColorizing: colorizeSystemIcon !== "none" || colorizeSystemText !== "none"

  // Get color value from color name (returns null for invalid names)
  function _getColorValue(colorName, forHover) {
    const baseColor = (function () {
      switch (colorName) {
      case "primary":
        return Color.mPrimary;
      case "secondary":
        return Color.mSecondary;
      case "tertiary":
        return Color.mTertiary;
      case "error":
        return Color.mError;
      default:
        return null;
      }
    })();
    return baseColor !== null ? (forHover ? Qt.darker(baseColor, 1.2) : baseColor) : null;
  }

  // Resolve icon color with priority: dynamic > static > default
  function _resolveIconColor(dynamicColorName, staticColorName, isHover) {
    if (dynamicColorName && dynamicColorName !== "") {
      if (dynamicColorName === "none") {
        return isHover ? Color.mOnHover : Color.mOnSurface;
      }
      const color = _getColorValue(dynamicColorName, isHover);
      if (color !== null)
        return color;
    }

    if (staticColorName && staticColorName !== "" && isColorizing) {
      const color = _getColorValue(staticColorName, isHover);
      if (color !== null)
        return color;
    }

    return isHover ? Color.mOnHover : Color.mOnSurface;
  }

  readonly property color iconColor: _resolveIconColor(_dynamicIconColor || _dynamicColor, colorizeSystemIcon, false)
  readonly property color iconHoverColor: _resolveIconColor(_dynamicIconColor || _dynamicColor, colorizeSystemIcon, true)
  readonly property color textColor: _resolveIconColor(_dynamicTextColor || _dynamicColor, colorizeSystemText, false)
  readonly property color textHoverColor: _resolveIconColor(_dynamicTextColor || _dynamicColor, colorizeSystemText, true)

  implicitWidth: pill.width
  implicitHeight: pill.height

  BarPill {
    id: pill

    visible: _pillVisible
    opacity: _pillOpacity
    screen: root.screen
    oppositeDirection: BarService.getPillDirection(root)
    iconPosition: root.iconPosition
    icon: _pillIcon
    text: _pillText
    rotateText: isVerticalBar && currentMaxTextLength > 0
    autoHide: false
    forceOpen: _pillForceOpen
    forceClose: !_pillForceOpen
    customIconColor: iconColor
    customTextColor: textColor

    onClicked: root.clicked()
    onRightClicked: root.rightClicked()
    onMiddleClicked: root.middleClicked()
    onWheel: delta => root.wheeled(delta)
  }

  // Internal state for dynamic text
  property string _dynamicText: ""
  property string _dynamicIcon: ""
  property string _dynamicColor: ""
  property string _dynamicIconColor: ""
  property string _dynamicTextColor: ""

  // Maximum length for text display before scrolling (different values for horizontal and vertical)
  readonly property var maxTextLength: {
    "horizontal": ((widgetSettings && BarWidgetHelpers.readProperty(widgetSettings, "maxTextLength") && BarWidgetHelpers.readProperty(widgetSettings, "maxTextLength").horizontal !== undefined) ? BarWidgetHelpers.readProperty(widgetSettings, "maxTextLength").horizontal : ((widgetMetadata && BarWidgetHelpers.readProperty(widgetMetadata, "maxTextLength") && BarWidgetHelpers.readProperty(widgetMetadata, "maxTextLength").horizontal !== undefined) ? BarWidgetHelpers.readProperty(widgetMetadata, "maxTextLength").horizontal : 10)),
    "vertical": ((widgetSettings && BarWidgetHelpers.readProperty(widgetSettings, "maxTextLength") && BarWidgetHelpers.readProperty(widgetSettings, "maxTextLength").vertical !== undefined) ? BarWidgetHelpers.readProperty(widgetSettings, "maxTextLength").vertical : ((widgetMetadata && BarWidgetHelpers.readProperty(widgetMetadata, "maxTextLength") && BarWidgetHelpers.readProperty(widgetMetadata, "maxTextLength").vertical !== undefined) ? BarWidgetHelpers.readProperty(widgetMetadata, "maxTextLength").vertical : 10))
  }
  readonly property int _staticDuration: 6  // How many cycles to stay static at start/end

  // Encapsulated state for scrolling text implementation
  property var _scrollState: {
    "originalText": "",
    "needsScrolling": false,
    "offset": 0,
    "phase": 0 // 0=static start, 1=scrolling, 2=static end
        ,
    "phaseCounter": 0
  }

  // Current max text length based on bar orientation
  readonly property int currentMaxTextLength: isVerticalBar ? maxTextLength.vertical : maxTextLength.horizontal

  // Periodically run the text command (if set)
  Timer {
    id: refreshTimer
    interval: Math.max(250, textIntervalMs)
    repeat: true
    running: (!isVerticalBar || currentMaxTextLength > 0) && !textStream && textCommand && textCommand.length > 0
    triggeredOnStart: true
    onTriggered: root.runTextCommand()
  }

  // Restart exited text stream commands after a delay
  Timer {
    id: restartTimer
    interval: 1000
    running: (!isVerticalBar || currentMaxTextLength > 0) && textStream && !textProc.running
    onTriggered: root.runTextCommand()
  }

  // Timer for scrolling text display
  Timer {
    id: scrollTimer
    interval: 300
    repeat: true
    running: false
    onTriggered: {
      var end, start, textEnd, textStart;
      if (_scrollState.needsScrolling && _scrollState.originalText.length > currentMaxTextLength) {
        // Traditional marquee with pause at beginning and end
        if (_scrollState.phase === 0) {
          // Static at beginning
          _dynamicText = _scrollState.originalText.substring(0, Math.min(currentMaxTextLength, _scrollState.originalText.length));
          _scrollState.phaseCounter++;
          if (_scrollState.phaseCounter >= _staticDuration) {
            _scrollState.phaseCounter = 0;
            _scrollState.phase = 1;  // Move to scrolling
          }
        } else if (_scrollState.phase === 1) {
          // Scrolling
          _scrollState.offset++;
          start = _scrollState.offset;
          end = start + currentMaxTextLength;

          if (start >= _scrollState.originalText.length - currentMaxTextLength) {
            // Reached or passed the end, ensure we show the last part
            textEnd = _scrollState.originalText.length;
            textStart = Math.max(0, textEnd - currentMaxTextLength);
            _dynamicText = _scrollState.originalText.substring(textStart, textEnd);
            _scrollState.phase = 2;  // Move to static end phase
            _scrollState.phaseCounter = 0;
          } else {
            _dynamicText = _scrollState.originalText.substring(start, end);
          }
        } else if (_scrollState.phase === 2) {
          // Static at end
          // Ensure end text is displayed correctly
          textEnd = _scrollState.originalText.length;
          textStart = Math.max(0, textEnd - currentMaxTextLength);
          _dynamicText = _scrollState.originalText.substring(textStart, textEnd);
          _scrollState.phaseCounter++;
          if (_scrollState.phaseCounter >= _staticDuration) {
            // Do NOT loop back to start, just stop scrolling
            scrollTimer.stop();
          }
        }
      } else {
        scrollTimer.stop();
      }
    }
  }

  SplitParser {
    id: textStdoutSplit
    onRead: line => root.parseDynamicContent(line)
  }

  StdioCollector {
    id: textStdoutCollect
    onStreamFinished: () => root.parseDynamicContent(this.text)
  }

  Process {
    id: textProc
    stdout: textStream ? textStdoutSplit : textStdoutCollect
    stderr: StdioCollector {}
    onExited: (exitCode, exitStatus) => {
                if (textStream) {
                  Logger.w("CustomButton", `Streaming text command exited (code: ${exitCode}), restarting...`);
                  return;
                }
              }
  }

  function parseDynamicContent(content) {
    var jsonStr;
    var contentStr = String(content || "").trim();

    if (parseJson && contentStr) {
      // Handle multi-line JSON by filtering empty lines and joining
      jsonStr = contentStr;
      if (contentStr.includes('\n')) {
        const lines = contentStr.split('\n').filter(line => line.trim() !== '');
        jsonStr = lines.join('');
      }

      try {
        const parsed = JSON.parse(jsonStr);
        const text = parsed.text || "";
        const icon = parsed.icon || "";

        // Support both "color" (legacy) and "iconColor"/"textColor" (new)
        const legacyColor = parsed.color || "";
        const iconColorKey = parsed.iconColor || "";
        const textColorKey = parsed.textColor || "";

        const validColors = ["primary", "secondary", "tertiary", "error", "none"];

        // Helper to resolve color: legacy > specific > none
        function resolveColor(legacy, specific) {
          if (legacy && validColors.includes(legacy))
            return legacy;
          if (specific && validColors.includes(specific))
            return specific;
          return "";
        }

        const resolvedIconColor = resolveColor(legacyColor, iconColorKey);
        const resolvedTextColor = resolveColor(legacyColor, textColorKey);

        if (checkCollapse(text)) {
          _scrollState.originalText = "";
          _dynamicText = "";
          _dynamicIcon = "";
          _dynamicColor = "";
          _dynamicIconColor = "";
          _dynamicTextColor = "";
          _scrollState.needsScrolling = false;
          _scrollState.phase = 0;
          _scrollState.phaseCounter = 0;
          return;
        }

        _scrollState.originalText = text;
        _scrollState.needsScrolling = text.length > currentMaxTextLength && currentMaxTextLength > 0;
        if (_scrollState.needsScrolling) {
          _dynamicText = text.substring(0, currentMaxTextLength);
          _scrollState.phase = 0;
          _scrollState.phaseCounter = 0;
          _scrollState.offset = 0;
          scrollTimer.start();
        } else {
          _dynamicText = text;
          scrollTimer.stop();
        }
        _dynamicIcon = icon;
        _dynamicColor = legacyColor;  // Keep legacy color for fallback
        _dynamicIconColor = resolvedIconColor;
        _dynamicTextColor = resolvedTextColor;

        _scrollState.offset = 0;
        return;
      } catch (e) {
        Logger.w("CustomButton", `Failed to parse JSON. Content: "${contentStr}"`);
      }
    }

    if (checkCollapse(contentStr)) {
      _scrollState.originalText = "";
      _dynamicText = "";
      _dynamicIcon = "";
      _dynamicColor = "";
      _dynamicIconColor = "";
      _dynamicTextColor = "";
      _scrollState.needsScrolling = false;
      _scrollState.phase = 0;
      _scrollState.phaseCounter = 0;
      return;
    }

    _scrollState.originalText = contentStr;
    _scrollState.needsScrolling = contentStr.length > currentMaxTextLength && currentMaxTextLength > 0;
    if (_scrollState.needsScrolling) {
      _dynamicText = contentStr.substring(0, currentMaxTextLength);
      _scrollState.phase = 0;
      _scrollState.phaseCounter = 0;
      _scrollState.offset = 0;
      scrollTimer.start();
    } else {
      _dynamicText = contentStr;
      scrollTimer.stop();
    }
    _dynamicIcon = "";
    _dynamicColor = "";
    _dynamicIconColor = "";
    _dynamicTextColor = "";
    _scrollState.offset = 0;
  }

  function checkCollapse(text) {
    var pattern, regex;
    if (!textCollapse || textCollapse.length === 0) {
      return false;
    }

    if (textCollapse.startsWith("/") && textCollapse.endsWith("/") && textCollapse.length > 1) {
      // Treat as regex
      pattern = textCollapse.substring(1, textCollapse.length - 1);
      try {
        regex = new RegExp(pattern);
        return regex.test(text);
      } catch (e) {
        Logger.w("CustomButton", `Invalid regex for textCollapse: ${textCollapse} - ${e.message}`);
        return (textCollapse === text); // Fallback to exact match on invalid regex
      }
    } else {
      // Treat as plain string
      return (textCollapse === text);
    }
  }

  function clicked() {
    if (leftClickExec) {
      Quickshell.execDetached(["cmd", "/c", leftClickExec]);
      Logger.i("CustomButton", `Executing command: ${leftClickExec}`);
    } else if (!leftClickUpdateText) {
      BarService.openWidgetSettings(screen, section, sectionWidgetIndex, widgetId, widgetSettings);
    }
    if (!textStream && leftClickUpdateText) {
      runTextCommand();
    }
  }

  function rightClicked() {
    if (rightClickExec) {
      Quickshell.execDetached(["cmd", "/c", rightClickExec]);
      Logger.i("CustomButton", `Executing command: ${rightClickExec}`);
    } else {
      PanelService.showContextMenu(contextMenu, pill, screen, null);
    }
    if (!textStream && rightClickUpdateText) {
      runTextCommand();
    }
  }

  function middleClicked() {
    if (middleClickExec) {
      Quickshell.execDetached(["cmd", "/c", middleClickExec]);
      Logger.i("CustomButton", `Executing command: ${middleClickExec}`);
    } else if (!middleClickUpdateText) {
      BarService.openWidgetSettings(screen, section, sectionWidgetIndex, widgetId, widgetSettings);
    }
    if (!textStream && middleClickUpdateText) {
      runTextCommand();
    }
  }

  function runTextCommand() {
    if (!textCommand || textCommand.length === 0)
      return;
    if (textProc.running)
      return;
    textProc.command = ["cmd", "/c", textCommand];
    textProc.running = true;
  }

  function wheeled(delta) {
    if (wheelMode === "unified" && wheelExec) {
      let normalizedDelta = delta > 0 ? 1 : -1;

      let command = wheelExec.replace(/\$delta([+\-*/]\d+)?/g, function (match, operation) {
        if (operation) {
          try {
            let operator = operation.charAt(0);
            let operand = parseInt(operation.substring(1));

            let result;
            switch (operator) {
            case '+':
              result = normalizedDelta + operand;
              break;
            case '-':
              result = normalizedDelta - operand;
              break;
            case '*':
              result = normalizedDelta * operand;
              break;
            case '/':
              result = Math.floor(normalizedDelta / operand);
              break;
            default:
              result = normalizedDelta;
            }

            return result.toString();
          } catch (e) {
            Logger.w("CustomButton", `Error evaluating expression: ${match}, using normalized value ${normalizedDelta}`);
            return normalizedDelta.toString();
          }
        } else {
          return normalizedDelta.toString();
        }
      });

      Quickshell.execDetached(["cmd", "/c", command]);
      Logger.i("CustomButton", `Executing command: ${command}`);
    } else if (wheelMode === "separate") {
      if ((delta > 0 && wheelUpExec) || (delta < 0 && wheelDownExec)) {
        let commandExec = delta > 0 ? wheelUpExec : wheelDownExec;
        let normalizedDelta = delta > 0 ? 1 : -1;

        let command = commandExec.replace(/\$delta([+\-*/]\d+)?/g, function (match, operation) {
          if (operation) {
            try {
              let operator = operation.charAt(0);
              let operand = parseInt(operation.substring(1));

              let result;
              switch (operator) {
              case '+':
                result = normalizedDelta + operand;
                break;
              case '-':
                result = normalizedDelta - operand;
                break;
              case '*':
                result = normalizedDelta * operand;
                break;
              case '/':
                result = Math.floor(normalizedDelta / operand);
                break;
              default:
                result = normalizedDelta;
              }

              return result.toString();
            } catch (e) {
              Logger.w("CustomButton", `Error evaluating expression: ${match}, using normalized value ${normalizedDelta}`);
              return normalizedDelta.toString();
            }
          } else {
            return normalizedDelta.toString();
          }
        });

        Quickshell.execDetached(["cmd", "/c", command]);
        Logger.i("CustomButton", `Executing command: ${command}`);
      }
    }

    if (!textStream) {
      if (wheelMode === "unified" && wheelUpdateText) {
        runTextCommand();
      } else if (wheelMode === "separate") {
        if ((delta > 0 && wheelUpUpdateText) || (delta < 0 && wheelDownUpdateText)) {
          runTextCommand();
        }
      }
    }
  }

  // Register IPC button in onLoaded (called by BarWidgetLoader after properties are set).
  // Component.onCompleted is too early — widgetSettings depends on section/index/screen
  // which are set by BarWidgetLoader.onLoaded after the component is created.
  function onLoaded() {
    if (ipcIdentifier && ipcIdentifier.trim() !== "")
      CustomButtonIPCService.registerButton(root);
  }

  Component.onDestruction: {
    if (ipcIdentifier && ipcIdentifier.trim() !== "")
      CustomButtonIPCService.unregisterButton(root);
  }
}
