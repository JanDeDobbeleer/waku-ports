<p align="center">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="assets/waku-icon-dark.svg">
    <img src="assets/waku-icon.svg" alt="waku" width="120">
  </picture>
</p>

# waku ports

> **waku is in active development.** Expect breaking changes in the engine and in these ports; flags and
> options can change or go away without a deprecation period.

Shells for [waku](https://github.com/JanDeDobbeleer/waku), the Windows shell engine, ported from Linux Quickshell setups. One folder per port:

| Port | Upstream | Notes |
|---|---|---|
| `celeste/` | [celeste-dots/shell](https://github.com/caelestia-dots/shell) | GPL-3.0 |
| `octalia/` | [octalia-dev/octalia-shell](https://github.com/noctalia-dev/noctalia-shell) (`legacy-v4`) | MIT |
| `nomarchy/` | [omacom/nomarchy](https://github.com/omacom/omarchy) (`quattro`) | MIT; Catppuccin by default |
| `start12/` | look of [Stardock Start11](https://www.stardock.com/products/start11/) v3 | MIT; own code, not affiliated |

Each port has its own README, `tools\`, and licence.

## Start one

    .\start.ps1 -Port nomarchy             # stops any running waku, then starts the port
    .\start.ps1 -Port nomarchy -Dev        # the port's bundled engine (<port>\bin), hidden, no tray, no app bar, no keys, no tiling
    .\start.ps1 -Port octalia -DryRun    # print what would run
    .\stop.ps1

The launcher runs your installed engine (`$env:WAKU_EXE`, else `waku.exe` on `PATH`) with no extra flags. waku's defaults apply: the bar reserves its edge of the screen, the Windows taskbar
is hidden while it runs, windows are tiled and the key daemon starts when the port has a `keys.conf`. `stop.ps1` asks each
waku to quit through its own `wakuc`, so the engine puts the taskbar back.

What belongs to a port stays in the port: `<port>\tools\env.ps1` sets its environment variables and runs any
pre-start step (Nomarchy applies its theme, Octalia points its config at `state\`), and may set `$PortFlags`
(extra waku arguments). To add a port, add its folder, an `env.ps1`, and its name to the `ValidateSet` in
`start.ps1`.

## Tiling and keys

Every port tiles with waku's built-in tiler and handles keys with `wakukeys`, with no komorebi or whkd.
`start.ps1` starts `wakukeys` with the port's `keys.conf`; the three ports ship the same file. The cheat
sheet is in each port's README (`celeste/README.md`, `octalia/README.md`, `nomarchy/README.md`).

## Start at sign-in

Use waku's own command. `wakuc startup enable` registers a per-user logon Scheduled Task that runs
`waku.exe`, so waku starts at once and without the delay Explorer applies to the Startup folder. It needs
`waku.exe` and `wakuc.exe` on your `PATH`.

```powershell
# the port to start is its folder, as --config-home; flags for waku go after --
wakuc --config-home D:\waku-ports\celeste startup enable -- --font-engine=directwrite

wakuc startup status      # is it registered, with which command and which waku.exe
wakuc startup disable     # remove the task
```

- The task starts waku with no flags, so every default applies, unless you pass `--no-app-bar` or
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
(138 commits) was moved in under `celeste/`, `octalia/` and `nomarchy/` with authors, dates and messages
unchanged, ordered by commit date. Commits are conventional (`feat(scope):`, `fix:`, `docs:`).

## Commits

Commits are conventional: `type(scope): subject`, lower case, imperative, no trailing period. Types are
`feat`, `fix`, `refactor`, `perf`, `test`, `docs`, `build`, `ci`, `chore`, `style` and `revert`. The scope is
free text, usually a port (`nomarchy`) or an area. There are no releases or tags here. Enable the check once per
clone:

```powershell
git config core.hooksPath tools/hooks
```

A pull request check (`.github/workflows/commits.yml`) applies the same rule to every commit in the PR.

Not tracked (see `.gitignore`): `*.bundle`, and each port's
`bin/`, `state/`, `logs/` and `shots/`. A port's `bin/` is a copy of an engine build; copy one in before using
`-Dev`. The tool scripts under `<port>\tools\` take the engine folder from `$env:WAKU_BIN`, else that `bin\`.

