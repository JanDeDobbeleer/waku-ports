import QtQuick
import "FontBuilder.js" as FB

// One font style of Tokens.font (headline, title, body, label, mono, icon): the fonts large,
// medium and small (and extraLarge for icons), and a FontBuilder for each in `builders`.
QtObject {
    id: root

    required property var cfg
    property real scale: 1

    readonly property font large: FB.fontFromConfig(cfg.large, cfg.family, scale)
    readonly property font medium: FB.fontFromConfig(cfg.medium, cfg.family, scale)
    readonly property font small: FB.fontFromConfig(cfg.small, cfg.family, scale)
    readonly property font extraLarge: FB.fontFromConfig(cfg.extraLarge ?? cfg.large, cfg.family, scale)

    readonly property var builders: ({
            extraLarge: FB.fromConfig(cfg.extraLarge ?? cfg.large, cfg.family, scale),
            large: FB.fromConfig(cfg.large, cfg.family, scale),
            medium: FB.fromConfig(cfg.medium, cfg.family, scale),
            small: FB.fromConfig(cfg.small, cfg.family, scale)
        })

    // Icon styles only: a builder from the small font at the given point size.
    function size(pointSize: int): var {
        return FB.fromConfig(cfg.small, cfg.family, scale).size(pointSize);
    }
}
