
const {Collection} = require('./collection');
const detail_url = "https://agefans.org/myapp/_get_ep_plays?ep={0}&anime_id={1}";

class DetailsCollection extends Collection {
    
    async fetch(url) {
        console.log("fetch 1");
        let doc = await super.fetch(url);
        console.log("fetch 2");

        let info_data = this.info_data;
        info_data.summary = doc.querySelector('.ellipsis_summary span:last-child').text;

        let boxes = doc.querySelectorAll('#plays_list .age-episode');
        let items = [];
        for (let box of boxes) {
            let item = glib.DataItem.new();
            item.title = box.text.trim();
            item.link = detail_url.replace('{0}', box.attr('play_ep')).replace('{1}', url.match(/[^\/]+$/)[0]);
            items.push(item);
        }

        return items;
    }

    reload(_, cb) {
        this.fetch(this.url).then((results)=>{
            this.setData(results);
            cb.apply(null);
        }).catch(function(err) {
            if (err instanceof Error) 
                err = glib.Error.new(305, err.message);
            cb.apply(err);
        });
        return true;
    }
}

module.exports = function(item) {
    return DetailsCollection.new(item);
};