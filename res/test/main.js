
class MainController extends Controller {

    load(data) {
        this.id = data.id;
        this.url = data.url;

        var cache = this.readCache();
        let list;
        if (cache) {
            list = cache.items;
        } else {
            list = [];
        }

        this.data = {
            list: list,
            loading: false,
        };

        if (cache) {
            let now = new Date().getTime();
            if (now - cache.time > 30 * 60 * 1000) {
                this.reload();
            }
        } else {
            this.reload();
        }
    }

    async onPressed(index) {
        var data = this.data.list[index];
        openVideo(data.link, data);
    }

    onRefresh() {
        this.reload();
    }

    onLoadMore() {
        this.setState(() => {
            this.data.loading = true;
        });
        setTimeout(() => {
            this.setState(() => {
                this.data.loading = false;
            });
        }, 5000);
    }

    async reload() {
        this.setState(() => {
            this.data.loading = true;
        });
        try {
            let res = await fetch(this.url);
            let html = await res.text();
            let items = this.parseHtml(html, this.url);
            localStorage['cache_' + this.id] = JSON.stringify({
                time: new Date().getTime(),
                items: items,
            });
            this.setState(()=>{
                this.data.list = items;
                this.data.loading = false;
            });
        } catch (e) {
            showToast(`${e}\n${e.stack}`);
            this.setState(()=>{
                this.data.loading = false;
            });
        }
    }

    readCache() {
        let cache = localStorage['cache_' + this.id];
        if (cache) {
            let json = JSON.parse(cache);
            return json;
        }
    }

    parseHtml(html, url) {
        let doc = HTMLParser.parse(html);
        
        if (this.id == 'home') {
            let titles = doc.querySelectorAll('.latest-tab-nav > ul > li');
            let cols = doc.querySelectorAll('.latest-tab-box .latest-item');
            let len = titles.length;
    
            let items = [];
            for (let i = 0; i < len; ++i) {
                let telem = titles[i];
                let item = {
                    header: true,
                    title: telem.text,
                };
                items.push(item);
    
                let celem = cols[i];
                let list = celem.querySelectorAll('.img-list > li');
                for (let node of list) {
                    let link = node.querySelector('a.play-img');
                    let img = link.querySelector('img');
                    let item = {
                        title: link.getAttribute('title'),
                        link: new URL(link.getAttribute('href'), url).toString(),
                        picture: img.getAttribute('src'),
                        subtitle: node.querySelector('.time').text,
                    };
                    items.push(item);
                }
            }
            return items;
        } else {
            let elems = doc.querySelectorAll('.img-list > li > a');
    
            let items = [];
    
            for (let i = 0, t = elems.length; i < t; ++i) {
                let elem = elems[i];
                let img = elem.querySelector('img');
    
                let item = {
                    title: elem.getAttribute('title'),
                    link: new URL(elem.getAttribute('href'), url).toString(),
                    picture: new URL(img.getAttribute('src'), url).toString(),
                    subtitle: elem.querySelector('p').text.trim(),
                };
                items.push(item);
            }
            return items;
        }
    }
}

module.exports = MainController;