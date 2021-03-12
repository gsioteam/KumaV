const {Collection} = require('./collection');

class VideoCollection extends Collection {

	async fetch(url) {
        let doc = await super.fetch(url);
        let script = doc.querySelector('.player_video script').text;
        var video_data;
        eval(script.replace(/var player_\w+/, 'video_data'));
        console.log(script.replace(/var player_\w+/, 'video_data'));
        console.log(JSON.stringify(video_data));
        let item = glib.DataItem.new();
        item.link = url;
        item.data = {
            url: video_data.url
        };
        return [item];
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