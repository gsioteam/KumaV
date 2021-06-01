const {Collection} = require('./collection');

function on_play(play_cfg, play_id) {
	if (play_cfg == 'url' || play_cfg == 'raw_flash' || play_cfg == 'raw' || play_cfg == 'm3u8' || play_cfg == 'mp4') {
		return '/myapp/_get_raw?id={0}'.replace('{0}',play_id);
	}

	if (play_cfg == 'quan1098') {
		return '/myapp/_get_qn_2?id={0}&quote=1'.replace('{0}',play_id);
	}

	if (play_cfg == 'qz1006' || play_cfg == 'qz1097' || play_cfg == 'qz1075') {
		return '/myapp/_get_e_i?url={0}&quote=1'.replace('{0}',play_id);
	}
	if (play_cfg == 'weibo') {
		return '/myapp/_get_w_2?url={0}&quote=1'.replace('{0}',play_id);
	}
	
	if (play_cfg == 'mp4s') {
		return '/myapp/_get_mp4s?id={0}'.replace('{0}',play_id);
	}		
}

class VideoCollection extends Collection {

	fetch(url) {
        return new Promise((resolve, reject)=>{
            let req = glib.Request.new('GET', url);
            // req.setHeader('User-Agent', 'Mozilla/5.0 (Linux; Android 6.0; Nexus 5 Build/MRA58N) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/85.0.4183.102 Mobile Safari/537.36');
            req.setHeader('Accept-Language', 'en-US,en;q=0.9');
            this.callback = glib.Callback.fromFunction(function() {
                if (req.getError()) {
                    reject(glib.Error.new(302, "Request error " + req.getError()));
                } else {
                    let body = req.getResponseBody();
                    if (body) {
                        resolve(body.text());
                    } else {
                        reject(glib.Error.new(301, "Response null body"));
                    }
                }
            });
            req.setOnComplete(this.callback);
            req.start();
        });
    }

    async request(url) {
        let text = await this.fetch(url);
        console.log("f result " + text);
		let json = JSON.parse(text);
		let items = [];
		for (let data of json.result) {
			let item = glib.DataItem.new();
            let path = on_play(data.cfg, data.id);
            let fullurl = "https://agefans.org" + path;
			item.link = fullurl;
			item.title = "线路 " + data.cfg_n;
			// let url = await 
            if (path) {
                item.data = {
                    link: fullurl,
                    handler: "handler",
                };
                items.push(item);
            }
		}

        return items;
    }

	async handler(data, resolve, reject) {
        data = data.toObject();
        try {
            console.log("Fetch " + data.link);
            let text = await this.fetch(data.link);
            try {
                let json = JSON.parse(text);
                text = decodeURIComponent(json.result);
            } catch (e) {
            }
            if (text.startsWith("//")) {
                text = "https:" + text;
            }
            resolve.apply(text);
        } catch (e) {
            reject.apply(e.message);
        }
	}

    reload(_, cb) {
        this.request(this.url).then((results)=>{
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
    return VideoCollection.new(item);
};