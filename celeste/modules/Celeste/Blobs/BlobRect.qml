import QtQuick

// Stand-in for celeste's C++ BlobRect (an SDF rounded rectangle that blends with its group and
// deforms like a spring). waku gap: no blending with the group, so the shape is a plain Rectangle
// in the group colour. The spring is ported: the shape stretches along its direction of travel and
// squashes across it, as the C++ BlobRect does (same integrator, constants and limits). The
// exclusion properties exist so shells load, and do nothing.
Item {
    id: root

    final property BlobGroup group
    final property real radius: 0
    final property real stiffness: 200
    final property real damping: 16
    final property real deformScale: 0.0005
    final property var exclude: []
    final property var excludeCorners: []
    final property real topLeftRadius: radius
    final property real topRightRadius: radius
    final property real bottomLeftRadius: radius
    final property real bottomRightRadius: radius
    // The spring's matrix (rest state is identity) and the same matrix about the shape's centre.
    final property matrix4x4 rawDeformMatrix
    final property matrix4x4 deformMatrix
    // Port: the C++ shape fuses with the frame by SDF blending. A plain rectangle abutting the
    // frame leaves an antialiasing seam, so a panel can grow into the frame by these amounts.
    final property real bleedTop: 0
    final property real bleedRight: 0
    final property real bleedBottom: 0

    // Spring state: the symmetric 2x2 deform matrix [m00 m01; m01 m11] and its velocities.
    final property real m00: 1
    final property real m01: 0
    final property real m11: 1
    final property real v00: 0
    final property real v01: 0
    final property real v11: 0
    final property bool springActive: false
    final property bool hasPrev: false
    final property real prevX: 0
    final property real prevY: 0

    readonly final property real maxStretch: 0.35
    readonly final property real restEpsilon: 0.002

    function resetSpring(): void {
        m00 = 1;
        m01 = 0;
        m11 = 1;
        v00 = 0;
        v01 = 0;
        v11 = 0;
        springActive = false;
        hasPrev = false;
        rawDeformMatrix = Qt.matrix4x4();
        deformMatrix = Qt.matrix4x4();
    }

    function updateMatrices(): void {
        rawDeformMatrix = Qt.matrix4x4(m00, m01, 0, 0, m01, m11, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1);
        updateCentredMatrix();
    }

    // Only the centred matrix depends on the size. A resize must not reassign rawDeformMatrix: a
    // panel's size can bind to it, and the reassignment would loop back into that binding.
    function updateCentredMatrix(): void {
        const cx = width / 2, cy = height / 2;
        deformMatrix = Qt.matrix4x4(m00, m01, 0, cx - (m00 * cx + m01 * cy), m01, m11, 0, cy - (m01 * cx + m11 * cy), 0, 0, 1, 0, 0, 0, 0, 1);
    }

    // One physics step of dt seconds; (x, y) is the centre in window coordinates.
    function step(dt: real, x: real, y: real): void {
        if (!hasPrev) {
            prevX = x;
            prevY = y;
            hasPrev = true;
            return;
        }
        if (dt > 0.1 || dt < 0.001) {
            // A skipped frame (as C++): re-sync the position, and check for rest so it never sticks.
            prevX = x;
            prevY = y;
            if (springActive)
                checkAtRest(0);
            return;
        }

        const velX = (x - prevX) / dt;
        const velY = (y - prevY) / dt;
        prevX = x;
        prevY = y;
        const speed = Math.sqrt(velX * velX + velY * velY);

        if (!springActive) {
            if (speed < 5)
                return;
            springActive = true;
        }

        // Target: R * diag(stretch, 1 / stretch) * R^T for the direction of travel.
        let t00 = 1, t01 = 0, t11 = 1;
        if (speed > 5) {
            const stretch = 1 + Math.min(speed * deformScale, maxStretch);
            const compress = 1 / stretch;
            const c = velX / speed, s = velY / speed;
            t00 = stretch * c * c + compress * s * s;
            t01 = (stretch - compress) * c * s;
            t11 = stretch * s * s + compress * c * c;
        }

        // Underdamped spring per component. The friction is implicit, so any dt stays stable.
        const invDamp = 1 / (1 + damping * dt);
        v00 = (v00 - stiffness * (m00 - t00) * dt) * invDamp;
        m00 += v00 * dt;
        v01 = (v01 - stiffness * (m01 - t01) * dt) * invDamp;
        m01 += v01 * dt;
        v11 = (v11 - stiffness * (m11 - t11) * dt) * invDamp;
        m11 += v11 * dt;

        updateMatrices();
        checkAtRest(speed);
    }

    function checkAtRest(speed: real): void {
        const e = restEpsilon;
        if (Math.abs(m00 - 1) < e && Math.abs(m01) < e && Math.abs(m11 - 1) < e && Math.abs(v00) < e && Math.abs(v01) < e && Math.abs(v11) < e && speed < 5)
            resetSpring();
    }

    // Runs only while the shape moves or the spring settles, so an idle panel costs nothing.
    final property bool moving: false
    onXChanged: moving = true
    onYChanged: moving = true
    onWidthChanged: {
        moving = true;
        updateCentredMatrix();
    }
    onHeightChanged: {
        moving = true;
        updateCentredMatrix();
    }

    FrameAnimation {
        running: root.moving && root.group !== null && root.visible
        onTriggered: {
            const p = root.mapToItem(null, root.width / 2, root.height / 2);
            root.step(frameTime, p.x, p.y);
            // At rest and not moving this frame: stop the loop.
            if (!root.springActive && Math.abs(p.x - root.prevX) < 0.01 && Math.abs(p.y - root.prevY) < 0.01)
                root.moving = false;
        }
    }

    // How far the deformation can pull a flush edge off its original line: the shape scales about
    // its centre, and a skew moves the ends of an edge in opposite directions. An edge that has
    // bleed (it is flush with the frame) grows by this much, so a stretch that settles back below
    // rest size never opens a gap to the frame. The C++ shape stays fused to the frame by SDF
    // blending instead.
    readonly final property real deformGapY: Math.max(0, height / 2 * (1 - m11) + Math.abs(m01) * width / 2) + 1
    readonly final property real deformGapX: Math.max(0, width / 2 * (1 - m00) + Math.abs(m01) * height / 2) + 1

    Rectangle {
        anchors.fill: parent
        transform: Matrix4x4 {
            matrix: root.deformMatrix
        }
        anchors.topMargin: -(root.bleedTop > 0 ? root.bleedTop + root.deformGapY : 0)
        anchors.rightMargin: -(root.bleedRight > 0 ? root.bleedRight + root.deformGapX : 0)
        anchors.bottomMargin: -(root.bleedBottom > 0 ? root.bleedBottom + root.deformGapY : 0)
        visible: root.group !== null
        // The group colour's alpha is applied through the item opacity, as the C++ shape does.
        color: root.group ? Qt.rgba(root.group.color.r, root.group.color.g, root.group.color.b, 1) : "transparent"
        topLeftRadius: root.topLeftRadius
        topRightRadius: root.topRightRadius
        bottomLeftRadius: root.bottomLeftRadius
        bottomRightRadius: root.bottomRightRadius
    }
}
