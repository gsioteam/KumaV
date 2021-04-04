
const {Collection} = require('./collection');
const crossCloudfare = require('./cross_cloudfare');

class SearchCollection extends Collection {
    
    constructor(data) {
        super(data);
        this.page = 0;
    }

    async fetch(url) {
        console.log(url);
        let doc = await super.fetch(url);
        let nodes = doc.querySelectorAll('.list-group > .item');

        console.log(nodes.length);
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

    makeURL(page) {
        let url = this.url.replace('{0}', glib.Encoder.urlEncode(this.key));
        return url.replace('{1}', `page/${page + 1}/`);
    }

    reload(data, cb) {
        this.key = data.get("key") || this.key;
        let page = 0;
        if (!this.key) return false;
        this.fetch(this.makeURL(page)).then((results)=>{
            this.page = page;
            this.setData(results);
            cb.apply(null);
        }).catch(function(err) {
            if (err instanceof Error) {
                console.log(err.stack);
                err = glib.Error.new(305, err.message);
            }
            cb.apply(err);
        });
        return true;
    } 

    loadMore(cb) {
        let page = this.page + 1;
        this.fetch(this.makeURL(page)).then((results)=>{
            this.page = page;
            this.appendData(results);
            cb.apply(null);
        }).catch(function(err) {
            if (err instanceof Error) {
                console.log(err.stack);
                err = glib.Error.new(305, err.message);
            }
            cb.apply(err);
        });
        return true;
    }
}

module.exports = function(data) {
    return SearchCollection.new(data ? data.toObject() : {});
};