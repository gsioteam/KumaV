
const {Collection} = require('./collection');
const crossCloudfare = require('./cross_cloudfare');

class HomeCollection extends Collection {

    constructor(data) {
        super(data);
        this.page = 0;
        this.pageUrl = data.pageUrl;
    }

    async _fetch(page) {
        if (!this.token) {
            let res = await crossCloudfare({
                url: this.url,
                settings: this.settings
            });
            let doc = res.document;
            let nodes = doc.querySelectorAll('body script:not([src])');
            for (let node of nodes) {
                let text = node.text.trim();
                if (text.match(/^var vars/)) {
                    var vars;
                    eval(text.replace(/^var vars/, 'vars'));
                    this.token = vars.token;
                }
            }
        }
        let res = await crossCloudfare({
            url: this.hrefUrl(page), 
            settings: this.settings
        });
        let data = JSON.parse(res.body.text());

        let items = [];
        for (let i = 0, t = data.items.length; i < t; i++) {
            let item = glib.DataItem.new();
            const it = data.items[i];
            item.title = it.title;
            item.subtitle = it.tagline;
            item.summary = it.plot;
            item.picture = it.poster;
            let arr = it.title.split(' ').map((e) => e.toLowerCase());
            arr.unshift(it.id.toString());

            item.link = this.url + '/' + arr.join('-');
            items.push(item);
        }
        return items;
    }

    hrefUrl(page) {
        return this.pageUrl.replace('{0}', page + 1).replace('{1}', this.token);
    }

    reload(_, cb) {
        let page = 0;
        this._fetch(page).then((items) => {
            this.page = page;
            this.setData(items);
            cb.apply(null);
        }).catch(function (err) {
            if (err instanceof Error) {
                console.log("Err " + err.message + " stack " + err.stack);
                err = glib.Error.new(305, err.message);
            }
            cb.apply(err);
        });
        return true;
    }

    loadMore(cb) {
        let page = this.page + 1;
        this._fetch(page).then((items) => {
            this.page = page;
            this.appendData(items);
            cb.apply(null);
        }).catch(function (err) {
            if (err instanceof Error) {
                console.log("Err " + err.message + " stack " + err.stack);
                err = glib.Error.new(305, err.message);
            }
            cb.apply(err);
        });
        return true;
    }
}


module.exports = function(info) {
    let data = info.toObject();
    // if (data.id === 'home') 
    //     return HomeCollection.new(data);
    // else return CategoryCollection.new(data);
    return HomeCollection.new(data);
};
