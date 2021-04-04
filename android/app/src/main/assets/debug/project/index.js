
const {Collection} = require('./collection');
const crossCloudfare = require('./cross_cloudfare');

class HomeCollection extends Collection {

    constructor(data) {
        super(data);
        this.page = 0;
    }

    async _fetch(page) {
        let url = this.hrefUrl(page);
        let doc = await super.fetch(url);
        let nodes = doc.querySelectorAll('.list-group > .item');

        let items = [];
        for (let node of nodes) {
            let img = node.querySelector('.post-thumb img');
            let item = glib.DataItem.new();
            item.picture = img.attr('data-src');
            item.title = img.attr('alt');
            item.subtitle = node.querySelector('.post-des .post-summary').text;
            item.link = node.querySelector('.post-thumb a').attr('href');

            items.push(item);
        }
        return items;
    }

    hrefUrl(page) {
        return this.url.replace('{0}', page + 1);
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
        if (this.url.indexOf('{0}') >= 0) {
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
        return false;
    }
}


module.exports = function(info) {
    let data = info.toObject();
    return HomeCollection.new(data);
};
