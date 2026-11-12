.pragma library

function iconNameFor(device) {
    const type = String(device && device.row ? device.row.type || "" : "").toLowerCase();
    const byType = {
        headphones: "audio-headphones", headset: "audio-headset", speaker: "audio-speakers",
        phone: "phone", tablet: "tablet", laptop: "computer", computer: "computer",
        keyboard: "input-keyboard", mouse: "input-mouse", controller: "input-gaming",
        watch: "watch", camera: "camera"
    };
    if (byType[type])
        return byType[type];
    const name = String(device && device.name ? device.name : "").toLowerCase();
    const matches = [
        [/headphone|buds|airpods|wh-|wf-|earbud|headset/, "audio-headset"],
        [/speaker|soundbar|boom|echo/, "audio-speakers"],
        [/mouse|mx master|pebble|trackpad/, "input-mouse"],
        [/keyboard|keys/, "input-keyboard"], [/phone|iphone|pixel|galaxy/, "phone"],
        [/watch/, "watch"], [/controller|gamepad|xbox|dualsense/, "input-gaming"]
    ];
    for (let i = 0; i < matches.length; i++) {
        if (matches[i][0].test(name))
            return matches[i][1];
    }
    return "bluetooth";
}

function hasConnected(devices) {
    for (let i = 0; i < devices.length; i++) {
        if (devices[i].connected)
            return true;
    }
    return false;
}

function connectedDevices(devices, disconnectedState) {
    const result = [];
    for (let i = 0; i < devices.length; i++) {
        if (devices[i].state !== disconnectedState)
            result.push(devices[i]);
    }
    return result;
}

function isConnected(device, connectedState) { return device && device.state === connectedState; }
