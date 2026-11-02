# waku ports

Shells for [waku](D:\waku), the Windows shell engine, ported from Linux Quickshell setups. One folder per port:

| Port | Upstream | Notes |
|---|---|---|
| `caelestia/` | [caelestia-dots/shell](https://github.com/caelestia-dots/shell) | GPL-3.0 |
| `noctalia/` | [noctalia-dev/noctalia-shell](https://github.com/noctalia-dev/noctalia-shell) (`legacy-v4`) | MIT |
| `omarchy/` | [omacom/omarchy](https://github.com/omacom/omarchy) (`quattro`) | MIT; Catppuccin by default |

Each port has its own README, `tools\`, and licence.

## Start one

    .\start.ps1 -Port omarchy             # stops any running waku, then starts the port
    .\start.ps1 -Port omarchy -Dev        # the port's bundled engine (<port>\bin), hidden, no tray, no app bar
    .\start.ps1 -Port noctalia -DryRun    # print what would run
    .\stop.ps1
    .\install-startup.ps1 -Port omarchy   # start it at sign-in (writes Startup\waku.lnk, keeps the old one as .bak)

The launcher runs your deployed engine (`D:\waku\dist\waku\waku.exe`) with `--register-app-bar --hide-taskbar`:
the bar reserves its edge of the screen and the Windows taskbar is hidden while it runs. `stop.ps1` asks each
waku to quit through its own `wakuc`, so the engine puts the taskbar back.

What belongs to a port stays in the port: `<port>\tools\env.ps1` sets its environment variables and runs any
pre-start step (Omarchy applies its theme, Noctalia points its config at `state\`), and may set `$PortFlags`
(extra waku arguments). To add a port, add its folder, an `env.ps1`, and its name to the `ValidateSet` in
`start.ps1` and `install-startup.ps1`.

## History

One straight line: no merge commits, fast-forward only. The three ports were separate repos; their history
(138 commits) was moved in under `caelestia/`, `noctalia/` and `omarchy/` with authors, dates and messages
unchanged, ordered by commit date. Commits are conventional (`feat(scope):`, `fix:`, `docs:`).

Not tracked (see `.gitignore`): `regress/` and `wt/` (scratch and engine builds), `*.bundle`, and each port's
`bin/`, `state/`, `logs/` and `shots/`. A port's `bin/` is a copy of an engine build; copy one in before using
`-Dev`.

The old repos are kept in `D:\waku-ports-backups\` as `<port>.bundle` and `<port>.git`, plus
`caelestia-pre-linearize.bundle` (Caelestia before its 31 merge commits were removed).
