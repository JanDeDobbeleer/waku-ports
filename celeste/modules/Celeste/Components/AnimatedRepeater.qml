import QtQuick

// Stand-in for celeste's C++ AnimatedRepeater (a Repeater that animates removals). This is a
// plain Repeater with the same model/delegate/count/itemAt/removeDuration surface.
// waku gap: the attached `AnimatedRepeater.adding` and `AnimatedRepeater.removing` cannot exist
// in pure QML, and removed items disappear at once. Delegates that read them must be edited to
// use a plain property (the callers are the bar workspace files, ported in a later package).
Repeater {
    final property int removeDuration: 300
}
