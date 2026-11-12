pragma Singleton

import QtQuick
import "Calc.js" as Calc
import "QalculatorHelpers.js" as QalculatorHelpers

// Port of celeste's C++ Qalculator singleton (libqalculate). This evaluates plain arithmetic
// with a hand-written parser (Calc.js); it never calls eval. Unit conversions, currencies,
// symbolic maths and everything else libqalculate does are not supported.
// waku gap: arithmetic only. An unsupported expression returns "error: <reason>".
QtObject {
    id: root

    final property string result
    final property string rawResult
    final property bool busy

    function evalSync(expr: string, printExpr: bool): string {
        return QalculatorHelpers.evalSync(expr, printExpr, Calc);
    }

    function evalAsync(expr: string): void {
        QalculatorHelpers.evalAsync(expr, Calc, root);
    }
}
