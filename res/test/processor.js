
function base64decode(str) {
    return Buffer.from(str, 'base64').toString();
}

class VideoProcesser extends Processor {
    async load(data) {
        this.value = {
            title: data.title,
            subtitle: data.subtitle,
            link: data.link,
        };
        let res = await fetch(data.link);
        let doc = HTMLParser.parse(await res.text());
        
        let items = [];

        let boxes = doc.querySelectorAll('.ui-box.marg');
        for (let box of boxes) {
            let id = box.getAttribute('id');
            if (typeof id === 'string') {
                if (id.match(/^playlist_/)) {
                    let title = box.querySelector('.down-title h2').text.trim();

                    let list = box.querySelectorAll('.video_list a');
                    for (let node of list) {
                        let url = new URL(node.getAttribute('href'), data.link).toString();
                        items.push({
                            title: node.text,
                            subtitle: title,
                            key: url,
                        });
                    }
                }
            }
        }

        this.value = {
            description: doc.querySelector('.juqing').text,
            items: items,
        };
    }

    async getVideo(key, data) {
        var cache = localStorage[`video:${key}`];
        if (cache) {
            return JSON.parse(cache);
        }

        let url = key;
        let response = await fetch(url);
        let doc = HTMLParser.parse(await response.text());

        let script = doc.querySelector('#bofang_box script').text;
        let pd = null;
        eval(script.replace(/var player_\w+/, 'pd'));

        let v_url = unescape(base64decode(pd.url));
        var ret = [{
            title: 'v1',
            url: v_url,
        }];
        localStorage[`video:${key}`] = JSON.stringify(ret);
        return ret;
    }

    async getResolution(data) {

    }

    clearVideoCache(key) {
        localStorage.removeItem(`video:${key}`);
    }
}

module.exports = VideoProcesser;