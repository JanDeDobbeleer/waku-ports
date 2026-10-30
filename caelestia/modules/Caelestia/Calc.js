.pragma library

// A small arithmetic evaluator for the launcher calculator. It is a recursive-descent parser over
// a fixed grammar, so no input is ever passed to eval or Function. Supported: numbers (with
// exponent), + - * / % ^ **, unary + -, parentheses, postfix %, the constants pi and e, and the
// functions in `functions`. A parse or math error throws an Error with a short message.

const constants = {
    "pi": Math.PI,
    "e": Math.E,
    "tau": 2 * Math.PI
};

const functions = {
    "sqrt": Math.sqrt,
    "cbrt": Math.cbrt,
    "sin": Math.sin,
    "cos": Math.cos,
    "tan": Math.tan,
    "asin": Math.asin,
    "acos": Math.acos,
    "atan": Math.atan,
    "sinh": Math.sinh,
    "cosh": Math.cosh,
    "tanh": Math.tanh,
    "ln": Math.log,
    "log": Math.log10,
    "log10": Math.log10,
    "log2": Math.log2,
    "exp": Math.exp,
    "abs": Math.abs,
    "floor": Math.floor,
    "ceil": Math.ceil,
    "round": Math.round,
    "pow": Math.pow,
    "min": Math.min,
    "max": Math.max
};

function tokenize(src) {
    const tokens = [];
    const re = /\s*(?:(\d+\.?\d*(?:[eE][+-]?\d+)?|\.\d+(?:[eE][+-]?\d+)?)|([A-Za-z_][A-Za-z0-9_]*)|(\*\*|[-+*\/%^(),×÷]))/y;
    let pos = 0;
    while (pos < src.length) {
        re.lastIndex = pos;
        const m = re.exec(src);
        if (!m) {
            if (/^\s*$/.test(src.slice(pos)))
                break;
            throw new Error("unexpected character '" + src.slice(pos).trim()[0] + "'");
        }
        pos = re.lastIndex;
        if (m[1] !== undefined)
            tokens.push({ t: "num", v: parseFloat(m[1]) });
        else if (m[2] !== undefined)
            tokens.push({ t: "id", v: m[2].toLowerCase() });
        else
            tokens.push({ t: "op", v: m[3] === "×" ? "*" : m[3] === "÷" ? "/" : m[3] });
    }
    return tokens;
}

function evaluate(src) {
    const tokens = tokenize(src);
    let i = 0;

    const peek = () => tokens[i];
    const isOp = v => tokens[i] && tokens[i].t === "op" && tokens[i].v === v;

    function expr() {
        let left = term();
        while (isOp("+") || isOp("-")) {
            const op = tokens[i++].v;
            const right = term();
            left = op === "+" ? left + right : left - right;
        }
        return left;
    }

    function term() {
        let left = unary();
        while (isOp("*") || isOp("/") || isOp("%")) {
            const op = tokens[i].v;
            // A trailing % (no operand after it) is a postfix percent, handled in postfix().
            if (op === "%" && !startsOperand(tokens[i + 1]))
                break;
            i++;
            const right = unary();
            if (op === "*")
                left = left * right;
            else if (op === "/")
                left = left / right;
            else
                left = left % right;
        }
        return left;
    }

    function startsOperand(tok) {
        return tok !== undefined && (tok.t === "num" || tok.t === "id" || (tok.t === "op" && (tok.v === "(" || tok.v === "-" || tok.v === "+")));
    }

    function unary() {
        if (isOp("-")) {
            i++;
            return -unary();
        }
        if (isOp("+")) {
            i++;
            return unary();
        }
        return power();
    }

    function power() {
        const base = postfix();
        if (isOp("^") || isOp("**")) {
            i++;
            return Math.pow(base, unary()); // right associative
        }
        return base;
    }

    function postfix() {
        let v = primary();
        while (isOp("%") && !startsOperand(tokens[i + 1])) {
            i++;
            v = v / 100;
        }
        return v;
    }

    function primary() {
        const tok = peek();
        if (!tok)
            throw new Error("unexpected end of expression");
        if (tok.t === "num") {
            i++;
            return tok.v;
        }
        if (tok.t === "id") {
            i++;
            if (isOp("(")) {
                const fn = functions[tok.v];
                if (!fn)
                    throw new Error("unknown function '" + tok.v + "'");
                i++;
                const args = [];
                if (!isOp(")")) {
                    args.push(expr());
                    while (isOp(",")) {
                        i++;
                        args.push(expr());
                    }
                }
                if (!isOp(")"))
                    throw new Error("missing ')'");
                i++;
                return fn.apply(null, args);
            }
            if (constants[tok.v] !== undefined)
                return constants[tok.v];
            throw new Error("unknown name '" + tok.v + "'");
        }
        if (tok.v === "(") {
            i++;
            const v = expr();
            if (!isOp(")"))
                throw new Error("missing ')'");
            i++;
            return v;
        }
        throw new Error("unexpected '" + tok.v + "'");
    }

    const value = expr();
    if (i < tokens.length)
        throw new Error("unexpected '" + tokens[i].v + "'");
    if (typeof value !== "number" || isNaN(value))
        throw new Error("not a number");
    return value;
}

function format(value) {
    if (!isFinite(value))
        return value > 0 ? "inf" : value < 0 ? "-inf" : "nan";
    if (Math.abs(value) >= 1e15 || (value !== 0 && Math.abs(value) < 1e-9))
        return value.toExponential(10).replace(/\.?0+e/, "e").replace("e+", "e");
    return String(parseFloat(value.toPrecision(12)));
}
