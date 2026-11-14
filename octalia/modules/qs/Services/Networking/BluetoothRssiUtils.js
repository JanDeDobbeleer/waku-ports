.pragma library

function onExited(root, out, BluetoothUtils) {
      var dbm, pct, text;
      try {
        text = out.text || "";
        dbm = BluetoothUtils.parseRssiOutput(text);
        if (root._currentAddr !== "" && dbm !== null) {
          pct = BluetoothUtils.dbmToPercent(dbm);
          if (pct !== null) {
            root.cache[root._currentAddr] = pct;
            root.version++;
          }
        }
      } catch (e) {} finally {
        root._currentAddr = "";
      }
}

function onTriggered(root, proc, BluetoothUtils) {
      var list = root.connectedDevices || [];
      if (!list || list.length === 0)
        return;
      if (root._index >= list.length)
        root._index = 0;
      var dev = list[root._index++];
      if (!dev)
        return;
      var addr = BluetoothUtils.macFromDevice(dev);
      if (!addr || addr.length < 7)
        return;
      if (proc.running)
        return; // avoid overlap
      root._currentAddr = addr;
      proc.command = ["sh", "-c", `bluetoothctl info "${addr}"`];
      try {
        proc.running = true;
      } catch (e) {}
}
