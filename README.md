<p align="center">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="assets/waku-icon-dark.svg">
    <img src="assets/waku-icon.svg" alt="waku" width="120">
  </picture>
</p>

# waku ports

Shells for [waku](https://github.com/JanDeDobbeleer/waku), the Windows shell engine, ported from Linux Quickshell setups. One folder per port:

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

The launcher runs your installed engine (`$env:WAKU_EXE`, else `waku.exe` on `PATH`) with `--register-app-bar --hide-taskbar`:
the bar reserves its edge of the screen and the Windows taskbar is hidden while it runs. `stop.ps1` asks each
waku to quit through its own `wakuc`, so the engine puts the taskbar back.

What belongs to a port stays in the port: `<port>\tools\env.ps1` sets its environment variables and runs any
pre-start step (Omarchy applies its theme, Noctalia points its config at `state\`), and may set `$PortFlags`
(extra waku arguments). To add a port, add its folder, an `env.ps1`, and its name to the `ValidateSet` in
`start.ps1`.

## Tiling and keys

Every port tiles with waku's built-in tiler and handles keys with `wakukeys`, with no komorebi or whkd.
`start.ps1` starts `wakukeys` with the port's `keys.conf`; the three ports ship the same file. The cheat
sheet is in each port's README (`caelestia/README.md`, `noctalia/README.md`, `omarchy/README.md`).

## Start at sign-in

Use waku's own command. `wakuc startup enable` registers a per-user logon Scheduled Task that runs
`waku.exe`, so waku starts at once and without the delay Explorer applies to the Startup folder. It needs
`waku.exe` and `wakuc.exe` on your `PATH`.

```powershell
# the port to start is its folder, as --config-home; flags for waku go after --
wakuc --config-home D:\waku-ports\caelestia startup enable -- --font-engine=directwrite

wakuc startup status      # is it registered, with which command and which waku.exe
wakuc startup disable     # remove the task
```

- The task starts waku with `--register-app-bar` and `--hide-taskbar` unless you pass `--no-app-bar` or
  `--keep-taskbar` to `startup enable`.
- Other waku flags follow `--`: `--font-engine=directwrite`, `--log-file <path>` (a JSON Lines diagnostics log; off unless you pass it).
- To switch to another port at sign-in, run `startup enable` again with that port's folder. It replaces the
  task. Run one port at a time.
- `startup enable` deletes an old `waku.lnk` in your Startup folder, with no backup, so waku does not start
  twice.
- The task runs waku directly. It does not run `start.ps1` or a port's `tools\env.ps1`, so put anything a port
  needs (an environment variable, a `PATH` entry) in your user environment.
- `startup enable` also registers the key handler `wakukeys.exe` when the port has a `keys.conf`. It reads that
  file by itself.
- Every port uses waku's built-in tiler (turned on in its `shell.qml`) and key handler (its `keys.conf`). waku
  supports no other tiling window manager.

The full reference is "Run at sign-in" in the waku repository's `docs/install.md`.

## History

One straight line: no merge commits, fast-forward only. The three ports were separate repos; their history
(138 commits) was moved in under `caelestia/`, `noctalia/` and `omarchy/` with authors, dates and messages
unchanged, ordered by commit date. Commits are conventional (`feat(scope):`, `fix:`, `docs:`).

## Commits

Commits are conventional: `type(scope): subject`, lower case, imperative, no trailing period. Types are
`feat`, `fix`, `refactor`, `perf`, `test`, `docs`, `build`, `ci`, `chore`, `style` and `revert`. The scope is
free text, usually a port (`omarchy`) or an area. There are no releases or tags here. Enable the check once per
clone:

```powershell
git config core.hooksPath tools/hooks
```

A pull request check (`.github/workflows/commits.yml`) applies the same rule to every commit in the PR.

Not tracked (see `.gitignore`): `regress/` and `wt/` (scratch and engine builds), `*.bundle`, and each port's
`bin/`, `state/`, `logs/` and `shots/`. A port's `bin/` is a copy of an engine build; copy one in before using
`-Dev`. The tool scripts under `<port>\tools\` take the engine folder from `$env:WAKU_BIN`, else that `bin\`.

