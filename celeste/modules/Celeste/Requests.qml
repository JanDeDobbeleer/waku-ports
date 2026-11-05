pragma Singleton

import QtQuick

// Port of upstream Requests: GET requests that bypass caches. get(url, onSuccess(body, meta),
// onError(errorString, meta), headers), where meta is {statusCode, headers} with lower case
// header names.
QtObject {
    function get(url: var, onSuccess: var, onError: var, headers: var): void {
        if (typeof onSuccess !== "function") {
            console.warn("Requests.get: onSuccess is not callable");
            return;
        }

        const xhr = new XMLHttpRequest();
        xhr.open("GET", String(url));
        xhr.setRequestHeader("Cache-Control", "no-cache, no-store");
        xhr.setRequestHeader("Pragma", "no-cache");
        if (headers)
            for (const name of Object.keys(headers))
                xhr.setRequestHeader(name, String(headers[name]));

        xhr.onreadystatechange = () => {
            if (xhr.readyState !== XMLHttpRequest.DONE)
                return;

            const meta = {
                statusCode: xhr.status,
                headers: {}
            };
            for (const line of (xhr.getAllResponseHeaders() ?? "").split(/\r?\n/)) {
                const i = line.indexOf(":");
                if (i > 0)
                    meta.headers[line.slice(0, i).trim().toLowerCase()] = line.slice(i + 1).trim();
            }

            if (xhr.status >= 200 && xhr.status < 400) {
                onSuccess(xhr.responseText, meta);
            } else {
                const error = xhr.status === 0 ? "Network error" : `HTTP ${xhr.status} ${xhr.statusText}`;
                if (typeof onError === "function")
                    onError(error, meta);
                else
                    console.warn("Requests.get: request failed with error", error);
            }
        };
        xhr.send();
    }

    // XMLHttpRequest keeps no cookies of its own here.
    function resetCookies(): void {
    }
}
