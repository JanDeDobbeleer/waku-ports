.pragma library

function substitute(text, args) {
    var result = text;
    if (args) {
        for (var i = 0; i < args.length; i++)
            result = result.replace("%" + (i + 1), String(args[i]));
    }
    return result;
}
