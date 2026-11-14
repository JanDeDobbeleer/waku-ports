pragma Singleton

import QtQuick
import Quickshell
import Celeste
import Celeste.Config
import Celeste.I18n
import waku.services as S
import qs.services
import qs.utils
import "SchemesHelpers.js" as SchemesHelpers

// The colour schemes the launcher offers. Upstream lists the schemes of the `celeste scheme`
// CLI. Here "dynamic" follows the wallpaper (Colours does the work through ColorScheme.fromImage)
// and the "material" flavours are fixed seed colours run through ColorScheme.fromColor.
// The choice lives in Colours, which persists it and restores it at startup.
Searcher {
    id: root

    readonly final property var seeds: Colours.seeds
    readonly final property string currentFlavour: Colours.seed
    readonly final property string currentScheme: `${Colours.scheme} ${currentFlavour}`
    readonly final property string currentVariant: Colours.flavour

    function transformSearch(search: string): string {
        return search.slice(`${GlobalConfig.launcher.actionPrefix}scheme `.length);
    }

    function selector(item: var): string {
        return SchemesHelpers.selector(item);
    }

    function reload(): void {
        build();
    }

    function coloursOf(scheme: var): var {
        return SchemesHelpers.coloursOf(scheme);
    }

    function build(): void {
        schemes.model = SchemesHelpers.build(seeds, Colours.current, S.ColorScheme, Colours.flavour, !Colours.currentLight);
    }

    function select(name: string, flavour: string): void {
        SchemesHelpers.select(name, flavour, Colours, Toaster, Tr, Toast.Info);
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
        required final property var modelData
        readonly final property string name: SchemesHelpers.name(modelData)
        readonly final property string flavour: SchemesHelpers.flavour(modelData)
        readonly final property var colours: SchemesHelpers.colours(modelData)

        function onClicked(list: var): void {
            SchemesHelpers.clicked(list, name, flavour, Colours, Toaster, Tr, Toast.Info);
        }
    }
}
