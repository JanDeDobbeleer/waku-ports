pragma Singleton

import Quickshell
import qs.compat

Singleton {
    readonly final property list<string> validImageTypes: ["jpeg", "png", "webp", "tiff", "svg"]
    readonly final property list<string> validImageExtensions: ["jpg", "jpeg", "png", "webp", "tif", "tiff", "svg"]

    function isValidImageByName(name: string): bool {
        return validImageExtensions.some(t => name.toLowerCase().endsWith(`.${t}`));
    }
}
