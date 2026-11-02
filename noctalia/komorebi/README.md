# komorebi for the noctalia port

`komorebi.json` is the komorebi configuration this port is tuned for. Noctalia draws a slim top bar
and nothing on the other three edges, so windows run flush to the left, right and bottom of the
screen and sit directly under the bar. Windows are 8 px apart (4 px container padding on each side)
and have a 2 px rounded border drawn inside the window.

`default_workspace_padding` is -6 on purpose: it cancels the 4 px container padding and the 2 px
komorebi keeps for the border at the screen edges, so a lone window fills the work area exactly
(checked with `komorebic state`: 0, 60, 2880 x 1860 on a 2880 x 1920 screen under a 60 px bar).
Apply it with `toolspply-komorebi.ps1` (it backs up your current file first).

It keeps `app_specific_configuration_path` pointing at `applications.json` in
`$Env:KOMOREBI_CONFIG_HOME`, so your own application rules still apply.
