.pragma library

// Gives a plain JS array the API of upstream's ListNode: values, count, at(), insert(), remove(),
// move(), clear(). The array is decorated in place with non-enumerable members, so it still
// serialises as a plain JSON array. Mutating methods change the array in place and do not emit a
// change signal; assign a copy to the property to notify bindings.
function list(arr) {
    if (!Array.isArray(arr))
        return arr;
    const def = (name, desc) => Object.defineProperty(arr, name, Object.assign({
        enumerable: false,
        configurable: true
    }, desc));
    def("values", {
        get: () => arr
    });
    def("count", {
        get: () => arr.length
    });
    // This JS engine has no Array.prototype.at
    def("at", {
        value: index => arr[index < 0 ? arr.length + index : index]
    });
    def("insert", {
        value: (props, index) => {
            if (index === undefined || index < 0 || index > arr.length)
                arr.push(props);
            else
                arr.splice(index, 0, props);
        }
    });
    def("remove", {
        value: index => {
            if (index >= 0 && index < arr.length)
                arr.splice(index, 1);
        }
    });
    def("move", {
        value: (from, to) => {
            if (from < 0 || from >= arr.length || to < 0 || to >= arr.length || from === to)
                return;
            arr.splice(to, 0, arr.splice(from, 1)[0]);
        }
    });
    def("clear", {
        value: () => {
            arr.length = 0;
        }
    });
    return arr;
}
