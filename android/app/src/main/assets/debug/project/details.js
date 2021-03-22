
const {Collection} = require('./collection');
const crossCloudfare = require('./cross_cloudfare');

class DetailsCollection extends Collection {
    
    async fetch(url) {
        let res = await crossCloudfare({
            url,
            settings: this.settings
        });
        let doc = res.document;

        let iframe = doc.querySelector('iframe');
        if (iframe) {
            let item = glib.DataItem.new();
            item.title = 'Video';
            item.link = url;
            return [item];
        } else {
            let seasons = doc.querySelectorAll('.seasons > a');
            if (seasons.length > 0) {
                let items = [];
                for (let snode of seasons) {
                    let title = snode.text;
                    let res = await crossCloudfare({
                        url: snode.attr('href'), 
                        settings: this.settings
                    });
                    let doc = res.document;
                    let links = doc.querySelectorAll('ul#episode-list > li.media');
                    for (let node of links) {
                        let item = glib.DataItem.new();
                        item.link = node.querySelector('a').attr('href');
                        let heading = node.querySelector('.media-heading');
                        item.title = heading.text;
                        item.subtitle = title;
                        items.push(item);
                    }
                }
                return items;
            }
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
    return DetailsCollection.new(item);
};