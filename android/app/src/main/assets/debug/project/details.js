
const {Collection} = require('./collection');

class DetailsCollection extends Collection {
    
    async fetch(url) {
        let pageUrl = new PageURL(url);
        let doc = await super.fetch(url);

        let info_data = this.info_data;
        let summay = doc.querySelector('.content').text.trim();
        let arr = summay.split('\n').map(function(str) {return str.trim();});
        arr.splice(arr.length - 1, 1);

        info_data.summary = arr.join('\n');

        let tabs = doc.querySelectorAll('.play_source .play_source_tab a');
        let lists = doc.querySelectorAll('.play_source .play_list_box .playlist_full');
        let len = tabs.length;
        let items = [];
        for (let i = 0; i < len; ++i) {
            let tab = tabs[i], list = lists[i];
            let subtitle = tab.text.substr(1).trim();
            let nodes = list.querySelectorAll('ul.content_playlist > li > a');
            for (let link of nodes) {
                let item = glib.DataItem.new();
                item.title = link.text;
                item.subtitle = subtitle;
                item.link = pageUrl.href(link.attr('href'));
                items.push(item);
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