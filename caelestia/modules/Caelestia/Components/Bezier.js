.pragma library

// Cubic bezier easing with the end points fixed at (0,0) and (1,1), like QEasingCurve::BezierSpline
// with one segment: valueForProgress(p) solves x(t) = p and returns y(t).
function cubic(x1, y1, x2, y2, p) {
    if (p <= 0)
        return 0;
    if (p >= 1)
        return 1;
    let lo = 0, hi = 1, t = p;
    for (let i = 0; i < 32; i++) {
        const u = 1 - t;
        const x = 3 * u * u * t * x1 + 3 * u * t * t * x2 + t * t * t;
        if (Math.abs(x - p) < 1e-6)
            break;
        if (x < p)
            lo = t;
        else
            hi = t;
        t = (lo + hi) / 2;
    }
    const u = 1 - t;
    return 3 * u * u * t * y1 + 3 * u * t * t * y2 + t * t * t;
}

// Fast out, slow in (0.4, 0, 0.2, 1).
function fastOutSlowIn(p) {
    return cubic(0.4, 0, 0.2, 1, p);
}

function clamp01(v) {
    return Math.max(0, Math.min(1, v));
}

function fractionInRange(playtime, start, duration) {
    return clamp01((playtime - start) / duration);
}
