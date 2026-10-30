pragma Singleton

import ".."
import QtQuick
import Quickshell
import Caelestia
import Caelestia.Config
import Caelestia.I18n
import wabar.services as S
import qs.services
import qs.utils

// The colour schemes the launcher offers. Upstream lists the schemes of the `caelestia scheme`
// CLI. Here "dynamic" follows the wallpaper (Colours does the work through ColorScheme.fromImage)
// and the "material" flavours are fixed seed colours run through ColorScheme.fromColor.
// The choice lives in Colours, which persists it and restores it at startup.
Searcher {
    id: root

    readonly property var seeds: Colours.seeds
    readonly property string currentFlavour: Colours.seed
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
        Colours.regenerate(false);
    }

    function select(name: string, flavour: string): void {
        Colours.scheme = name;
        Colours.seed = name === "dynamic" ? "wallpaper" : flavour;
        apply();
        Toaster.toast(Tr.tr("Colour scheme changed"), `${name} ${flavour}`, "palette", Toast.Success, 2500);
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
