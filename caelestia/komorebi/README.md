# komorebi for the caelestia port

`komorebi.json` is the komorebi configuration this port is tuned for: 6 px around the work area and
3 px around each window, so windows sit clear of caelestia's left bar and frame, and a 4 px rounded
border. Apply it with `tools\apply-komorebi.ps1` (it backs up your current file first).

It keeps `app_specific_configuration_path` pointing at `applications.json` in
`$Env:KOMOREBI_CONFIG_HOME`, so your own application rules still apply.
