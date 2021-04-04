
class Fetcher {
    constructor({url, settings, body, method, headers, userAgent}) {
        this.url = url;
        this.settings = settings;
        this.body = body;
        this.method = method || 'GET';
        this.headers = headers || {};
        this.userAgent = userAgent;
    }

    run() {
        return new Promise((resolve, reject) => {
            let req = glib.Request.new(this.method, this.url);
            let ua = this.settings.get('user-agent'); //this.userAgent; //this.settings.get('user-agent');
            if (ua) {
                console.log('user-agent ' + ua);
                req.setHeader('user-agent', ua);
            }
            let cf_clearance = this.settings.get('cf_clearance');
            if (cf_clearance) {
                console.log('cf_clearance ' + cf_clearance);
                req.setHeader('cookie', `cf_clearance=${cf_clearance};`);
            }
            if (this.body) {
                req.setBody(glib.Data.fromString(this.body));
            }
            for (let key in this.headers) {
                req.setHeader(key, this.headers[key]);
            }
            // must keep callback object, other ways will not get callback.
            this.callback = glib.Callback.fromFunction(function() {
                if (req.getError()) {
                    reject(glib.Error.new(302, "Request error " + req.getError()));
                } else {
                    let body = req.getResponseBody();
                    if (body) {
                        let headers = req.getResponseHeaders().toObject();
                        let newHeaders = {};
                        for (let key in headers) {
                            newHeaders[key.toLowerCase()] = headers[key];
                        }
                        resolve({
                            body,
                            headers: newHeaders
                        });
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

class ProcessBrowser {
    constructor(url) {
        let idx = url.indexOf('?');
        this.url = idx < 0 ? `${url}?t=${Date.now()}` : `${url}&t=${Date.now()}`;
    }

    run() {
        return new Promise((resolve, reject) => {
            let browser = glib.Browser.new(this.url, "cookie: cf_clearance", true);
            this.callback = glib.Callback.fromFunction((map) => {
                let error = browser.getError();
                console.log('Error ' + error);
                if (error) {
                    reject(glib.Error.new(303, "Browser error " + error));
                } else {
                    resolve(map.toObject());
                }
            });
            browser.setOnComplete(this.callback);
            if (this.userAgent) {
                browser.setUserAgent(this.userAgent);
            }
            browser.start();
        });
    }
}

async function runProcess(options, try_count) {
    let fetcher = new Fetcher(options);
    let settings = options.settings;
    let url = options.url;
    let response = await fetcher.run();
    if (response.headers['content-type'].indexOf('text/html') >= 0) {
        let doc = glib.GumboNode.parse(response.body);
        if (doc.querySelector('#cf-content')) {
            let browser = new ProcessBrowser(url);
            browser.userAgent = options.userAgent;
            try {
                let data = await browser.run();
                settings.set('cf_clearance', data['cf_clearance']);
                settings.set('user-agent', data['user-agent']);
                settings.save();
            } catch (e) {
            }
            console.log('try again!');

            if (try_count < 3) {
                return await runProcess(options, try_count + 1);
            } else {
                throw new Error('Cross failed');
            }
        }
        response.document = doc;
    }
    return response;
}

module.exports = function ({url, settings, body, method, headers, userAgent}) {
    // if (userAgent == null) {
    //     userAgent = 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/89.0.4389.90 Safari/537.36';
    // }
    return runProcess({url, settings, body, method, headers, userAgent}, 0);
};