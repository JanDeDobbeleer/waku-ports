pragma Singleton

import QtQuick
import qs.services
import "NetworkConnectionHelpers.js" as H

/**
 * NetworkConnection
 *
 * Centralized utility for network connection logic. Provides a single source of truth
 * for connecting to wireless networks from the bar popouts.
 *
 * Usage:
 * ```qml
 * import qs.utils
 *
 * NetworkConnection.handleConnect(network, (network) => {
 *     // Show password dialog
 *     root.passwordNetwork = network;
 *     root.showPasswordDialog = true;
 * });
 * ```
 */
QtObject {
    id: root

    /**
     * Handle network connection with automatic disconnection if needed.
     * If there's an active network different from the target, disconnects first,
     * then connects to the target network.
     *
     * @param network The network to connect to
     * @param onPasswordNeeded Optional callback function(network) called when password is needed
     */
    function handleConnect(network: AccessPoint, onPasswordNeeded: var): void {
        if (!network)
            return;

        if (Nmcli.active && Nmcli.active.ssid !== network.ssid) {
            Nmcli.disconnectFromNetwork();
            Qt.callLater(root.connectToNetwork, network, onPasswordNeeded);
        } else {
            root.connectToNetwork(network, onPasswordNeeded);
        }
    }

    /**
     * Connect to a wireless network.
     * Handles both secured and open networks, checks for saved profiles,
     * and shows password dialog if needed.
     *
     * @param network The network to connect to
     * @param onPasswordNeeded Optional callback function(network) called when password is needed
     */
    function connectToNetwork(network: AccessPoint, onPasswordNeeded: var): void {
        if (!network)
            return;

        if (network.isSecure && !Nmcli.hasSavedProfile(network.ssid))
            H.connectWithPasswordCheck(Nmcli, network, onPasswordNeeded);
        else
            Nmcli.connectToNetwork(network.ssid, "", network.bssid, null);
    }

    /**
     * Connect to a wireless network with a provided password.
     * Used by password dialogs when the user has already entered a password.
     *
     * @param network The network to connect to
     * @param password The password to use for connection
     * @param onResult Optional callback function(result) called with connection result
     */
    function connectWithPassword(network: AccessPoint, password: string, onResult: var): void {
        if (!network)
            return;

        Nmcli.connectToNetwork(network.ssid, password, network.bssid, onResult);
    }
}
