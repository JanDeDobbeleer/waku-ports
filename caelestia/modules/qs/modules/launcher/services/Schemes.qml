pragma Singleton

import ".."
import QtQuick
import Quickshell
import Caelestia.Config
import wabar.services as S
import qs.services
import qs.utils

// The colour schemes the launcher offers. Upstream lists the schemes of the `caelestia scheme`
// CLI. Here "dynamic" follows the wallpaper (Colours does the work through ColorScheme.fromImage)
// and the "material" flavours are fixed seed colours run through ColorScheme.fromColor.
// wabar gap: the choice is not persisted, and a wallpaper change in a fixed scheme re-applies
// Colours' fallback seed.
Searcher {
    id: root

    readonly property var seeds: ({
            "purple": "#6750A4",
            "rose": "#A8627B",
            "teal": "#006A6A",
            "blue": "#1B5EA8",
            "green": "#3B6A3B",
            "orange": "#9C4A00"
        })

    property string currentFlavour: "wallpaper"
    readonly property string currentScheme: `${Colours.scheme} ${currentFlavour}`
    readonly property string currentVariant: Colours.flavour

    function transformSearch(search: string): string {
        return search.slice(`${GlobalConfig.launcher.actionPrefix}scheme `.length);
    }

    function selector(item: var): string {
        return `${item.name} ${item.flavour}`;
    }

    function reload(): void {
        build();
    }

    function coloursOf(scheme: var): var {
        const out = {};
        for (const k of ["surface", "primary", "outline"])
            out[k] = scheme?.colors?.[k] ?? "transparent";
        return out;
    }

    function build(): void {
        const flat = [
            {
                name: "dynamic",
                flavour: "wallpaper",
                colours: {
                    surface: Colours.current.m3surface,
                    primary: Colours.current.m3primary,
                    outline: Colours.current.m3outline
                }
            }
        ];
        for (const [flavour, seed] of Object.entries(seeds))
            flat.push({
                name: "material",
                flavour,
                seed,
                colours: coloursOf(S.ColorScheme.fromColor(seed, Colours.flavour, !Colours.currentLight))
            });
        schemes.model = flat;
    }

    // Applies the current scheme and variant to Colours.
    function apply(): void {
        const seed = seeds[currentFlavour];
        if (Colours.scheme === "dynamic" || !seed)
            Colours.regenerate(false);
        else
            Colours.applyScheme(S.ColorScheme.fromColor(seed, Colours.flavour, !Colours.currentLight), false);
    }

    function select(name: string, flavour: string): void {
        Colours.scheme = name;
        currentFlavour = flavour;
        apply();
    }

    list: schemes.instances
    useFuzzy: GlobalConfig.launcher.useFuzzy.schemes
    keys: ["name", "flavour"]
    weights: [0.9, 0.1]

    Component.onCompleted: build()

    Variants {
        id: schemes

        Scheme {}
    }

    component Scheme: QtObject {
        required property var modelData
        readonly property string name: modelData?.name ?? ""
        readonly property string flavour: modelData?.flavour ?? ""
        readonly property var colours: modelData?.colours ?? ({})

        function onClicked(list: AppList): void {
            list.screenState.launcher = false;
            root.select(name, flavour);
        }
    }
}
