import QtQuick

// Port of upstream CircularBuffer: the last `capacity` pushed values. Changing the capacity
// clears the buffer. `maximum` is the largest value held.
QtObject {
    id: root

    final property int capacity: 0
    readonly final property int count: _data.length
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
        const next = _data.length >= capacity ? _data.slice(_data.length - capacity + 1) : _data.slice();
        next.push(value);
        _data = next;
        _max = Math.max(...next);
        valuesChanged();
    }

    function clear(): void {
        if (_data.length === 0)
            return;
        _data = [];
        _max = 0;
        valuesChanged();
    }

    function at(index: int): real {
        if (index < 0 || index >= _data.length)
            return 0;
        return _data[index];
    }
}
