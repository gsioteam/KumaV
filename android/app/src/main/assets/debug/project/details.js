
const {Collection} = require('./collection');
const crossCloudfare = require('./cross_cloudfare');

class DetailsCollection extends Collection {
    
    async fetch(url) {
        let doc = await super.fetch(url);
        let lists = doc.querySelectorAll('.listserver .listep');
        let items = [];
        for (let list of lists) {
            let title = list.querySelector('.ep').text.trim().replace(':', '');
            let links = list.querySelectorAll('a');
            for (let link of links) {
                let url = link.attr('data-link');
                if (url.match(/quickvideo\.net/)) {
                    let item = glib.DataItem.new();
                    item.title = link.text;
                    item.subtitle = title;
                    item.link = url;
                    items.push(item);
                }
            }
        }
        return items;
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
    return DetailsCollection.new(item);
};