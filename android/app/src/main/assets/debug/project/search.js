
const {Collection} = require('./collection');

class SearchCollection extends Collection {
    
    constructor(data) {
        super(data);
        this.page = 0;
    }

    async fetch(url) {
        let pageUrl = new PageURL(url);
        let doc = await super.fetch(url);
        let nodes = doc.querySelectorAll('ul.list-unstyled > li.card');

        let results = [];
        for (let node of nodes) {
            let item = glib.DataItem.new();

            item.link = pageUrl.href(node.querySelector('a.stretched-link-').attr('href'));
            item.title = node.querySelector('.anime-title').text;
            item.picture = pageUrl.href(node.querySelector('img.card-img-').attr('data-src'));
            item.subtitle = node.querySelector('ul.list-unstyled > li:last-child > .text-light').text;
            item.summary = node.querySelector('.catalog_summary > span:last-child').text.trim();
            results.push(item);
        }
        return results;
    }

    makeURL(page) {
        return this.url.replace('{0}', glib.Encoder.urlEncode(this.key)).replace('{1}', page + 1);
    }

    reload(data, cb) {
        this.key = data.get("key") || this.key;
        let page = data.get("page") || 0;
        if (!this.key) return false;
        this.fetch(this.makeURL(page)).then((results)=>{
            this.page = page;
            this.setData(results);
            cb.apply(null);
        }).catch(function(err) {
            if (err instanceof Error) 
                err = glib.Error.new(305, err.message);
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
            if (err instanceof Error) 
                err = glib.Error.new(305, err.message);
            cb.apply(err);
        });
        return true;
    }
}

module.exports = function(data) {
    return SearchCollection.new(data ? data.toObject() : {});
};