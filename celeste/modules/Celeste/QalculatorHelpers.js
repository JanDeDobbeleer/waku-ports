.pragma library

function calculate(expr, calc) {
    try {
        const value = calc.evaluate(expr);
        const text = calc.format(value);
        return [text, ""];
    } catch (error) {
        const message = error && error.message !== undefined ? error.message : String(error);
        return [message, message];
    }
}

function evalSync(expr, printExpr, calc) {
    if (!expr)
        return "";
    const result = calculate(expr, calc);
    return printExpr ? (result[1] ? "error: " + result[1] : expr.trim() + " = " + result[0]) : result[0];
}

function evalAsync(expr, calc, target) {
    if (!expr) {
        target.result = "";
        target.rawResult = "";
        target.busy = false;
        return;
    }
    const result = calculate(expr, calc);
    target.result = result[1] ? "error: " + result[1] : expr.trim() + " = " + result[0];
    target.rawResult = result[0];
    target.busy = false;
}
