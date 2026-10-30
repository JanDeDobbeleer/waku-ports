import QtQuick

// Stub for caelestia's C++ BlobRect (an SDF rounded rectangle that blends with its group and
// deforms like a spring). wabar gap: a plain Rectangle in the group colour. The spring and
// exclusion properties exist so shells load, and do nothing. The deform matrices stay identity.
Item {
    id: root

    property BlobGroup group
    property real radius: 0
    property real stiffness: 0
    property real damping: 0
    property real deformScale: 1
    property var exclude: []
    property var excludeCorners: []
    property real topLeftRadius: radius
    property real topRightRadius: radius
    property real bottomLeftRadius: radius
    property real bottomRightRadius: radius
    property matrix4x4 deformMatrix
    property matrix4x4 rawDeformMatrix
    // Port: the C++ shape fuses with the frame by SDF blending. A plain rectangle abutting the
    // frame leaves an antialiasing seam, so a panel can grow into the frame by these amounts.
    property real bleedTop: 0
    property real bleedRight: 0
    property real bleedBottom: 0

    Rectangle {
        anchors.fill: parent
        anchors.topMargin: -root.bleedTop
        anchors.rightMargin: -root.bleedRight
        anchors.bottomMargin: -root.bleedBottom
        visible: root.group !== null
        // The group colour's alpha is applied through the item opacity, as the C++ shape does.
        color: root.group ? Qt.rgba(root.group.color.r, root.group.color.g, root.group.color.b, 1) : "transparent"
        topLeftRadius: root.topLeftRadius
        topRightRadius: root.topRightRadius
        bottomLeftRadius: root.bottomLeftRadius
        bottomRightRadius: root.bottomRightRadius
    }
}
