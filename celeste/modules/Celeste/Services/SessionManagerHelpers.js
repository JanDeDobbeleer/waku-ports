.pragma library

function actionFor(command, actions) {
    if (!command || command.length === 0)
        return "";
    if (command.length >= 2 && command[0] === "loginctl" && command[1] === "lock-session")
        return "lock";
    if (command.length === 1)
        return actions[command[0]] || "";
    return "";
}
