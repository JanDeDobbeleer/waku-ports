# komorebi for the noctalia port

`komorebi.json` is the komorebi configuration this port is tuned for. Noctalia draws a slim top bar
and nothing on the other three edges, so the work area has no padding: windows run flush to the left,
right and bottom of the screen. Windows are 8 px apart (4 px container padding on each side) and have
a 2 px rounded border drawn inside the window. Apply it with `tools\apply-komorebi.ps1` (it backs up
your current file first).

It keeps `app_specific_configuration_path` pointing at `applications.json` in
`$Env:KOMOREBI_CONFIG_HOME`, so your own application rules still apply.
