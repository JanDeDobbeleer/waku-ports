import QtQuick

// Stand-in for QtQuick.Templates.TextField: a Control around a TextInput.
// The enums repeat the TextInput values so `TextField.AlignHCenter` and `TextField.Password` work.
// waku gap: no built-in placeholder drawing (celeste draws its own), no context menu.
Control {
    id: field

    enum HorizontalAlignment {
        AlignLeft = 1,
        AlignRight = 2,
        AlignHCenter = 4,
        AlignJustify = 8
    }

    enum EchoMode {
        Normal,
        NoEcho,
        Password,
        PasswordEchoOnEdit
    }

    enum RenderType {
        QtRendering,
        NativeRendering,
        CurveRendering
    }

    property alias text: input.text
    readonly property alias displayText: input.displayText
    final property string placeholderText
    final property color placeholderTextColor: "gray"
    property alias color: input.color
    property alias selectionColor: input.selectionColor
    property alias selectedTextColor: input.selectedTextColor
    property alias selectedText: input.selectedText
    property alias font: input.font
    property alias readOnly: input.readOnly
    property alias echoMode: input.echoMode
    property alias validator: input.validator
    property alias inputMask: input.inputMask
    property alias inputMethodHints: input.inputMethodHints
    property alias maximumLength: input.maximumLength
    property alias passwordCharacter: input.passwordCharacter
    property alias cursorPosition: input.cursorPosition
    property alias cursorVisible: input.cursorVisible
    property alias cursorDelegate: input.cursorDelegate
    property alias selectByMouse: input.selectByMouse
    property alias horizontalAlignment: input.horizontalAlignment
    property alias verticalAlignment: input.verticalAlignment
    property alias renderType: input.renderType
    property alias wrapMode: input.wrapMode
    readonly property alias cursorRectangle: input.cursorRectangle
    readonly property alias contentWidth: input.contentWidth
    readonly property alias contentHeight: input.contentHeight
    readonly property alias acceptableInput: input.acceptableInput
    readonly property alias length: input.length
    readonly property alias inputMethodComposing: input.inputMethodComposing

    signal accepted
    signal editingFinished
    signal textEdited
    signal pressed(var event)
    signal released(var event)

    function clear(): void {
        input.clear();
    }

    function selectAll(): void {
        input.selectAll();
    }

    function deselect(): void {
        input.deselect();
    }

    function copy(): void {
        input.copy();
    }

    function cut(): void {
        input.cut();
    }

    function paste(): void {
        input.paste();
    }

    function select(start: int, end: int): void {
        input.select(start, end);
    }

    function insert(position: int, text: string): void {
        input.insert(position, text);
    }

    function remove(start: int, end: int): void {
        input.remove(start, end);
    }

    function positionAt(x: real): int {
        return input.positionAt(x);
    }

    function undo(): void {
        input.undo();
    }

    function redo(): void {
        input.redo();
    }

    focus: false
    activeFocusOnTab: true
    implicitWidth: Math.max(implicitBackgroundWidth, input.implicitWidth + leftPadding + rightPadding)
    implicitHeight: Math.max(implicitBackgroundHeight, input.implicitHeight + topPadding + bottomPadding)
    onActiveFocusChanged: {
        if (activeFocus)
            input.forceActiveFocus();
    }

    TextInput {
        id: input

        x: field.leftPadding
        y: field.topPadding
        width: field.availableWidth
        height: field.availableHeight
        clip: true
        selectByMouse: true
        onAccepted: field.accepted()
        onEditingFinished: field.editingFinished()
        onTextEdited: field.textEdited()
    }

    // Press and release signals for callers (the real template emits these on mouse input).
    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.NoButton
        hoverEnabled: false
    }

    TapHandler {
        gesturePolicy: TapHandler.ReleaseWithinBounds
        onPressedChanged: {
            if (pressed)
                field.pressed(null);
            else
                field.released(null);
        }
    }
}
