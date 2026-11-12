pragma Singleton

import QtQuick

// Port of upstream Tr (TranslatorInternal in C++). The port has no translation catalogues, so
// every lookup is the identity: tr("x") is "x". The `%1` placeholders stay in the string for the
// caller's `.arg()`, except in mark()/markN(), which take their arguments like upstream and
// substitute them.
QtObject {
    id: root

    // Never changes; upstream bumps this when the language changes. CUtils.dependency(Tr.__trsChanged)
    final property bool __trsChanged: false

    readonly final property var supportedLanguages: ["en"]
    final property string language: ""
    readonly final property var locale: Qt.locale()

    function formatDateTime(date: date, fmt: var): string {
        return date.toLocaleString(locale, fmt);
    }

    function _subst(text: string, args: var): string {
        let out = text;
        if (args)
            for (let i = 0; i < args.length; i++)
                out = out.replace("%" + (i + 1), String(args[i]));
        return out;
    }

    function _plural(text: string, plural: string, n: int): string {
        return (n === 1 ? text : plural).replace("%n", String(n));
    }

    function tr(text: string): string {
        return text;
    }

    function trCtx(text: string, context: string): string {
        return text;
    }

    function trN(text: string, plural: string, n: int): string {
        return _plural(text, plural, n);
    }

    function trCtxN(text: string, plural: string, n: int, context: string): string {
        return _plural(text, plural, n);
    }

    function trMarked(text: string): string {
        return text;
    }

    // Marks a string for translation where it is declared, translated later by trMarked().
    function mark(text: string, args: var): string {
        return _subst(text, args);
    }

    function markCtx(text: string, context: string, args: var): string {
        return _subst(text, args);
    }

    function markN(text: string, plural: string, n: int, args: var): string {
        return _subst(_plural(text, plural, n), args);
    }

    function markCtxN(text: string, plural: string, n: int, context: string, args: var): string {
        return _subst(_plural(text, plural, n), args);
    }
}
