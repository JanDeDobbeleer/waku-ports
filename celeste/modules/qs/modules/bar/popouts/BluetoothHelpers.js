.pragma library

function connectedCount(devices) {
    let connected = 0;
    for (let i = 0; i < devices.length; i++) {
        if (devices[i].connected)
            connected++;
    }
    return connected;
}

function sortedDevices(devices) {
    return devices.slice().sort(function (a, b) {
        return (b.connected - a.connected) || (b.paired - a.paired) || a.name.localeCompare(b.name);
    }).slice(0, 5);
}

function forgetDevice(device) {
    device.forget();
}
