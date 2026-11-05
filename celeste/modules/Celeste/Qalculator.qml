pragma Singleton

import QtQuick
import "Calc.js" as Calc

// Port of celeste's C++ Qalculator singleton (libqalculate). This evaluates plain arithmetic
// with a hand-written parser (Calc.js); it never calls eval. Unit conversions, currencies,
// symbolic maths and everything else libqalculate does are not supported.
// waku gap: arithmetic only. An unsupported expression returns "error: <reason>".
QtObject {
    id: root

    property string result
    property string rawResult
    property bool busy

    function evaluate(expr: string): var {
        try {
            const value = Calc.evaluate(expr);
            const text = Calc.format(value);
            return {
                formatted: `${expr.trim()} = ${text}`,
                raw: text
            };
        } catch (e) {
            const msg = e.message ?? String(e);
            return {
                formatted: `error: ${msg}`,
                raw: msg
            };
        }
    }

    // waku gap: the C++ name is `eval`, which QML rejects as a method name.
    function evalSync(expr: string, printExpr: bool): string {
        if (!expr)
            return "";
        const r = evaluate(expr);
        return (printExpr ?? true) ? r.formatted : r.raw;
    }

    function evalAsync(expr: string): void {
        if (!expr) {
            result = "";
            rawResult = "";
            busy = false;
            return;
        }
        const r = evaluate(expr);
        result = r.formatted;
        rawResult = r.raw;
        busy = false;
    }
}
