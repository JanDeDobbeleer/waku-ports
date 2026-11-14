import QtQuick
import "FontBuilder.js" as FB

// One font style of Tokens.font (headline, title, body, label, mono, icon): the fonts large,
// medium and small (and extraLarge for icons), and cfg and scale for Tokens.styled.
QtObject {
    id: root

    required final property var cfg
    final property real scale: 1

    readonly final property font large: FB.sizeFont(cfg, "large", scale)
    readonly final property font medium: FB.sizeFont(cfg, "medium", scale)
    readonly final property font small: FB.sizeFont(cfg, "small", scale)
    readonly final property font extraLarge: FB.sizeFont(cfg, "extraLarge", scale)
}
