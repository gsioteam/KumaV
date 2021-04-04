class Collection extends glib.Collection {

    constructor(data) {
        super(data);
        this.url = data.url || data.link;
    }

    fetch(url, ops) {
        let headers;
        if (ops) headers = ops.headers;
        return new Promise((resolve, reject)=>{
            let req = glib.Request.new('GET', url);
            if (headers) {
                for (let key in headers) {
                    req.setHeader(key, headers[key]);
                }
            }
            this.callback = glib.Callback.fromFunction(function() {
                if (req.getError()) {
                    reject(glib.Error.new(302, "Request error " + req.getError()));
                } else {
                    let body = req.getResponseBody();
                    if (body) {
                        resolve(glib.GumboNode.parse(body));
                    } else {
                        reject(glib.Error.new(301, "Response null body"));
                    }
                }
            });
            req.setOnComplete(this.callback);
            req.start();
        });
    }
}

module.exports = {
    Collection
};