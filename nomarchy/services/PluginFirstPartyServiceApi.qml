import QtQuick
import "PluginFirstPartyServiceApiUtils.js" as PluginFirstPartyServiceApiUtils

// Narrow proxy for the non-authentication first-party services used by the
// built-in bar. It intentionally has no generic property or method forwarding.
QtObject {
  id: api

  required property string ownerPluginId
  required property string serviceId

  property bool stayAwake: false
  property bool enabled: false
  property bool doNotDisturb: false
  property var activePlayer: null
  property var sourcePlayers: []
  property bool active: false
  property var peers: []

  property var _setIdleEnabled: null
  property var _setNightlight: null
  property var _setDoNotDisturb: null
  property var _runAction: null
  property var _playerKey: null
  property var _selectPlayer: null
  property var _refresh: null

  function setIdleEnabled(value: bool): void {
    if (serviceId === "nomarchy.idle") PluginFirstPartyServiceApiUtils.invoke(_setIdleEnabled, [!!value], api)
  }

  function setNightlight(value: bool): void {
    if (serviceId === "nomarchy.nightlight") PluginFirstPartyServiceApiUtils.invoke(_setNightlight, [!!value], api)
  }

  function setDoNotDisturb(value: bool): void {
    if (serviceId === "nomarchy.notifications") PluginFirstPartyServiceApiUtils.invoke(_setDoNotDisturb, [!!value], api)
  }

  function runAction(action: string, showFeedback: bool, playerId: string): void {
    if (serviceId === "nomarchy.media")
      PluginFirstPartyServiceApiUtils.invoke(_runAction, [String(action || ""), !!showFeedback, String(playerId || "")], api)
  }

  function playerKey(player: var): string {
    return serviceId === "nomarchy.media" && _playerKey
      ? PluginFirstPartyServiceApiUtils.invoke(_playerKey, [player], api) : ""
  }

  function selectPlayer(playerId: string): void {
    if (serviceId === "nomarchy.media") PluginFirstPartyServiceApiUtils.invoke(_selectPlayer, [String(playerId || "")], api)
  }

  function refresh(): void {
    if (serviceId === "nomarchy.remote-session") PluginFirstPartyServiceApiUtils.invoke(_refresh, [], api)
  }
}
