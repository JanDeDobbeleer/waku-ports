# komorebi for the noctalia port

`komorebi.json` is the komorebi configuration this port is tuned for. Noctalia draws a slim top bar
and nothing on the other three edges, so the windows sit in an even frame: 6 px of workspace padding
plus 3 px of container padding keep them about 12 physical pixels (6 logical) clear of the bar and of
the left, right and bottom edges, 6 px apart from each other, with a 4 px rounded border. The
wallpaper shows in the gap, as in the caelestia port. These are the values the caelestia port uses.

Apply it with `tools\apply-komorebi.ps1` (it backs up your current file first).

It keeps `app_specific_configuration_path` pointing at `applications.json` in
`$Env:KOMOREBI_CONFIG_HOME`, so your own application rules still apply.

## Corner radius

Windows 11 rounds a window by 8 logical pixels and komorebi's rounded border follows it, so the port
sets the bar's inverted corners (`BarBackground.qml`, `Style.radiusXS`) and the screen corners
(`screenRadiusRatio` 0.4, which gives 8) to the same 8 px. Screen corners stay off unless you turn
on `showScreenCorners`.
