
let functions = {
    toString(target, that, args) {
        return '[object Storage]';
    },
    setItem(target, that, args) {
        target.set(args[0], args[1].toString());
    },
    getItem(target, that, args) {
        return target.get(args[0]);
    },
    removeItem(target, that, args) {
        target.remove(args[0]);
    },
    clear() {
        target.clear();
    }
};

globalThis.localStorage = new Proxy({}, {
    get(target, prop, receiver) {
        let func = functions[prop];
        if (typeof func == 'function') {
            return func;
        }
        return globalThis._storage.get(prop);
    },
    set(target, prop, value) {
        let func = functions[prop];
        if (typeof func == 'function') {
            func(globalThis._storage, prop, value);
        } else {
            globalThis._storage.set(prop, value.toString());
        }
        return true;
    },
});