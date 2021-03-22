
const {Collection} = require('./collection');
const crossCloudfare = require('./cross_cloudfare');

class SearchCollection extends Collection {
    
    constructor(data) {
        super(data);
    }

    async fetch(url) {
        let res = await crossCloudfare({
            url,
            settings: this.settings
        });
        let doc = res.document;
        let results = [];

        let nodes = doc.querySelectorAll('#movies figure');
        if (nodes.length > 0) {
            let item = glib.DataItem.new();
            item.type = glib.DataItem.Type.Header;
            item.title = "Movies";
            results.push(item);

            for (let node of nodes) {
                let item = glib.DataItem.new();
                item.picture = node.querySelector('img').attr('src');
                let subnode = node.querySelector('figcaption');
                item.subtitle = item.title = subnode.attr('title');
                item.link = subnode.querySelector('a').attr('href');
                results.push(item);
            }
        }

        nodes = doc.querySelectorAll('#series figure');
        if (nodes.length > 0) {
            let item = glib.DataItem.new();
            item.type = glib.DataItem.Type.Header;
            item.title = "Series";
            results.push(item);

            for (let node of nodes) {
                let item = glib.DataItem.new();
                item.picture = node.querySelector('img').attr('src');
                let subnode = node.querySelector('figcaption');
                item.subtitle = item.title = subnode.attr('title');
                item.link = subnode.querySelector('a').attr('href');
                results.push(item);
            }
        }

        return results;
    }

    makeURL() {
        return this.url.replace('{0}', glib.Encoder.urlEncode(this.key));
    }

    reload(data, cb) {
        this.key = data.get("key") || this.key;
        if (!this.key) return false;
        this.fetch(this.makeURL()).then((results)=>{
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
}

module.exports = function(data) {
    return SearchCollection.new(data ? data.toObject() : {});
};