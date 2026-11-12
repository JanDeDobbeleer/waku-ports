pragma Singleton
import QtQuick
import Quickshell
import qs.compat
import "IpcRegistryUtils.js" as IpcRegistryUtils

// Every ShellIpc handler, so the shell can answer an nomarchy-shell call over
// its own socket instead of through a qs ipc client started per call. It
// answers only what qs ipc would: the first live, enabled handler for a
// target, and only the functions that handler declares. Those are allowed by
// name, never inferred from what a function call happens to reach: QObject
// methods such as destroy() are callable but not enumerable.
Singleton {
  id: root

  property var handlers: []

  // A bare handler's own functions (signals and hooks such as targetChanged),
  // which qs ipc never exposes and neither may the socket.
  readonly property var builtins: IpcRegistryUtils.functionNames(bareHandler)

  IpcHandler {
    id: bareHandler
    enabled: false
  }

  // Bumped whenever a handler comes, goes or changes its target, so each
  // ShellIpc re-checks whether it leads its target.
  property int revision: 0

  function touch(): void {
    revision++
  }

  function register(handler: var): void {
    if (handlers.indexOf(handler) === -1) handlers.push(handler)
    touch()
  }

  function unregister(handler: var): void {
    var index = handlers.indexOf(handler)
    if (index !== -1) handlers.splice(index, 1)
    touch()
  }

  // Whether `handler` is the first live handler for its target. One with no
  // target, or not registered yet, doesn't lead, so it can't enable before the
  // registry knows of it. `revision` is there only to make a binding re-check.
  function leads(handler: var, revision: int): bool {
    return IpcRegistryUtils.leads(handler, handlers)
  }

  function handlerFor(target: string): var {
    return IpcRegistryUtils.handlerFor(target, handlers)
  }

  function declaredFunctions(handler: var): var {
    return IpcRegistryUtils.declaredFunctions(handler, builtins)
  }

  // { ran: true, output } once the function ran; { ran: false } when it did
  // not (unknown target or function, wrong argument count), so the caller
  // can ask qs ipc for its exact answer without running anything twice.
  function call(target: string, method: string, args: var): var {
    return IpcRegistryUtils.call(target, method, args, handlers, builtins)
  }

}
