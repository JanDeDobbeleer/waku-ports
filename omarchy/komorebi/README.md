# komorebi for the omarchy port

`komorebi.json` is the komorebi configuration this port is tuned for. It gives windows the look
Omarchy's Hyprland config does: a 2 px square border (`border_style` "Square", no rounding), 5 px
between the window and its neighbours' edges on each side (`default_container_padding` 5, so 10 px
between two windows) and about 10 px from the screen edges (3 px workspace padding + 5 px container
padding + the 2 px border). All of it is physical pixels, which is what komorebi counts.

The border colours are the Catppuccin theme's: the focused window (`single`, `stack`, `monocle`) takes the
theme's `accent`, the others its `muted`, a floating window `yellow` and a locked unfocused one `orange`.
Seven workspaces, all BSP (Hyprland's dwindle), named 1 to 7 to match the bar.

Apply it with `tools\apply-komorebi.ps1`. It backs up your current `komorebi.json`, writes this one with
the border colours of the theme the shell is on now (from `state\home\.local\state\omarchy\current\theme`)
and asks komorebi to reload. Run it again after you switch theme to move the borders along. `-WhatIf`
shows what it would do; `-KeepColours` copies the file as it is, Catppuccin colours included.

It keeps `app_specific_configuration_path` pointing at `applications.json` in
`$Env:KOMOREBI_CONFIG_HOME`, so your own application rules still apply.

## Corners

komorebi draws the border square, but Windows 11 still rounds the windows themselves by 8 logical px, so
the corner of a window sits a little inside the square border. komorebi cannot change that.
