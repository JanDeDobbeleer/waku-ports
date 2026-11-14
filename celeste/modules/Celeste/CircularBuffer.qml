import QtQuick
import "CircularBufferHelpers.js" as CircularBufferHelpers

// Port of upstream CircularBuffer: the last `capacity` pushed values. Changing the capacity
// clears the buffer. `maximum` is the largest value held.
QtObject {
    id: root

    final property int capacity: 0
    readonly final property int count: CircularBufferHelpers.length(_data)
    readonly final property real maximum: _max

    signal valuesChanged

    final property var _data: []
    final property real _max: 0

    onCapacityChanged: {
        _data = [];
        _max = 0;
        valuesChanged();
    }

    function push(value: real): void {
        if (capacity <= 0)
            return;
        _data = CircularBufferHelpers.push(_data, capacity, value);
        _max = CircularBufferHelpers.maximum(_data);
        valuesChanged();
    }

    function clear(): void {
        if (CircularBufferHelpers.length(_data) === 0)
            return;
        _data = [];
        _max = 0;
        valuesChanged();
    }

    function at(index: int): real {
        return CircularBufferHelpers.at(_data, index);
    }
}
