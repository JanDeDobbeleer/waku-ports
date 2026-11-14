.pragma library
function isValid(validator, text, emptyIsValid) {
    if (!validator || (!text && emptyIsValid))
        return true;
    if (validator instanceof RegExp)
        return validator.test(text);
    return !!validator(text);
}
