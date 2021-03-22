const {Collection} = require('./collection');
const crossCloudfare = require('./cross_cloudfare');

class VideoCollection extends Collection {

	async fetch(url) {
        let res = await crossCloudfare({
            url, 
            settings: this.settings
        });
        let doc = res.document;
        let iframe = doc.querySelector('iframe');
        let src = iframe.attr('src');

        let pageUrl = new PageURL(src);
        let search = pageUrl.url.search;
        let query = {};
        search.substr(1).split('&').forEach(function(str) {
            let arr = str.split('=');
            if (arr.length === 2) query[arr[0]] = arr[1];
        });
        console.log(`id=${query['url']}&server=3`);
        res = await crossCloudfare({
            url: "https://theofficetv.com/playerv1/result.php",
            settings: this.settings,
            body: `id=${query['url']}&server=3`,
            method: 'POST',
            headers: {
                'Content-Type': 'application/x-www-form-urlencoded; charset=UTF-8'
            }
        });
        doc = res.document;
        if (doc) {
            let iframe = doc.querySelector('iframe');
            let src = iframe.attr('src');
            let m = src.match(/vidsrc\.php/);
            if (m) {
                let url = new URL(src);
                src = url.searchParams['url'];
            } else {
                m = src.match(/akaplayer\.com\/([^/]+)/);
                if (m) {
                    src = 'https://gomo.to/movie/' + m[1];
                } else {
                    src = null;
                }
            }
            if (src) {
                console.log('src: ' + src);
                let res = await crossCloudfare({
                    url: src,
                    settings: this.settings,
                });
                let doc = res.document;
                let script = doc.querySelector('script:not([src])');

                let onReady;
                var $ = function() {
                    return {
                        ready(fn) {onReady = fn;},
                        show() {},
                        hide() {}
                    };
                };
                let requestOptions;
                $.ajax = function(ops) {
                    requestOptions = ops;
                };
                var document = {};
                eval(script.text);
                if (onReady) {
                    console.log('ready !');
                    onReady();
                }
                if (requestOptions) {
                    let headers = requestOptions.headers || {};
                    headers['Content-Type'] = 'application/x-www-form-urlencoded; charset=UTF-8';
                    let data = requestOptions.data;
                    let arr = [];
                    for (let key in data) {
                        arr.push(`${key}=${data[key]}`);
                    }
                    console.log(requestOptions.url);
                    let res = await crossCloudfare({
                        method: requestOptions.type,
                        settings: this.settings,
                        url: requestOptions.url,
                        headers: headers,
                        body: arr.join('&')
                    });
                    data = JSON.parse(res.body.text());
                    let linkUrl = data[0];
                    res = await crossCloudfare({
                        url: linkUrl,
                        settings: this.settings
                    });
                    let doc = res.document;
                    let source;
                    var jwplayer = function() {
                        return {
                            setup(data) {
                                source = data;
                            },
                            onPlay() {},
                            onTime() {},
                            onComplete() {},
                            getState() {return ''}
                        }
                    };
                    let ss = doc.querySelectorAll('body script:not([src])');
                    let scriptText;
                    for (let s of ss) {
                        let text = s.text.trim();
                        if (text.startsWith('eval')) {
                            scriptText = text;
                        }
                    }
                    console.log(scriptText);
                    eval(scriptText);
                    if (source) {
                        let items = [];
                        for (let i = 0, t = source.sources.length; i < t; ++i) {
                            let d = source.sources[i];
                            let item = glib.DataItem.new();
                            item.link = linkUrl;
                            item.title = 'R' + (i+1);
                            item.data = {
                                url: d.file
                            };
                            items.push(item);
                        }
                        return items;
                    }
                }
            } else {
                console.log('no src.');
            }
        } else {
            console.log('no!');
        }

        return [];
    }

    reload(_, cb) {
        this.fetch(this.url).then((results)=>{
            this.setData(results);
            cb.apply(null);
        }).catch(function(err) {
            if (err instanceof Error) {
                console.log("Err " + err.message + " stack " + err.stack);
                err = glib.Error.new(305, err.message);
            }
            cb.apply(err);
        });
        return true;
    }
}

module.exports = function(item) {
    return VideoCollection.new(item);
};