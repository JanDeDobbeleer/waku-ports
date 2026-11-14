.pragma library

function discordClients(applications) {
    var clients = [];
    var discordApp = applications.find(app => app.id === "discord");
    if (discordApp && discordApp.clients) {
      discordApp.clients.forEach(client => {
                                   clients.push({
                                                  "name": client.name,
                                                  "configPath": client.path,
                                                  "themePath": `${client.path}/themes/octalia.theme.css`
                                                });
                                 });
    }
    return clients;
}

function codeClients(applications) {
    var clients = [];
    var codeApp = applications.find(app => app.id === "code");
    if (codeApp && codeApp.clients) {
      codeApp.clients.forEach(client => {
                                // Extract base config directory from theme path
                                var themePath = client.path;
                                var baseConfigDir = "";
                                if (client.name === "code") {
                                  // For VSCode: ~/.vscode/extensions/... -> ~/.vscode
                                  baseConfigDir = "~/.vscode";
                                } else if (client.name === "codium") {
                                  // For VSCodium: ~/.vscode-oss/extensions/... -> ~/.vscode-oss
                                  baseConfigDir = "~/.vscode-oss";
                                }
                                clients.push({
                                               "name": client.name,
                                               "configPath": baseConfigDir,
                                               "themePath": "" // resolved dynamically via resolvedCodeClientPaths()
                                             });
                              });
    }
    return clients;
}
