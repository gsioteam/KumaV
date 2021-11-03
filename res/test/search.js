
const baseURL = 'http://www.qimiqimi.co/index.php/vod/search/wd/{0}/page/{1}.html';

class SearchController extends Controller {

    load() {
        let str = localStorage['hints'];
        let hints = [];
        if (str) {
            let json = JSON.parse(str);
            if (json.push) {
                hints = json;
            }
        }
        this.data = {
            list: [],
            focus: false,
            hints: hints,
            text: '',
            loading: false,
        };
        this.hasMore = true;
    }

    makeURL(word, page) {
        return baseURL.replace('{0}', encodeURIComponent(word)).replace('{1}', page + 1);
    }

    onSearchClicked() {
        this.findElement('input').submit();
    } 

    onTextChange(text) {
        console.log("onTextChange " + text);
        this.data.text = text;
    }

    async onTextSubmit(text) {
        console.log("onTextSubmit " + text);
        let hints = this.data.hints;
        if (text.length > 0) {
            if (hints.indexOf(text) < 0) {
                this.setState(()=>{
                    hints.unshift(text);
                    while (hints.length > 30) {
                        hints.pop();
                    }
    
                    localStorage['hints'] = JSON.stringify(hints);
                });
            }
            
            this.setState(()=>{
                this.data.loading = true;
            });
            try {
                let list = await this.request(this.makeURL(text, 0));
                this.key = text;
                this.page = 0;
                this.hasMore = true;
                this.setState(()=>{
                    this.data.list = list;
                    this.data.loading = false;
                });
            } catch(e) {
                showToast(`${e}\n${e.stack}`);
                this.setState(()=>{
                    this.data.loading = false;
                });
            }
        }
    }

    onTextFocus() {
        this.setState(()=>{
            this.data.focus = true;
        });
    }

    onTextBlur() {
        this.setState(()=>{
            this.data.focus = false;
        });
    }

    onPressed(index) {
        var data = this.data.list[index];
        console.log(`test ${data.link}`);
        openVideo(data.link, data);
    }

    onHintPressed(index) {
        let hint = this.data.hints[index];
        if (hint) {
            this.setState(()=>{
                this.data.text = hint;
                this.findElement('input').blur();
                this.onTextSubmit(hint);
            });
        }
    }

    async onRefresh() {
        let text = this.key;
        if (!text) return;
        try {
            let list = await this.request(this.makeURL(text, 0));
            this.page = 0;
            this.hasMore = true;
            this.setState(()=>{
                this.data.list = list;
                this.data.loading = false;
            });
        } catch(e) {
            showToast(`${e}\n${e.stack}`);
            this.setState(()=>{
                this.data.loading = false;
            });
        }
    }

    async onLoadMore() {
        if (!this.hasMore) return;
        let page = this.page + 1;
        try {
            let list = await this.request(this.makeURL(text, page));
            if (list.length == 0) {
                this.hasMore = false;
            }
            this.page = page;
            this.setState(()=>{
                for (let item in list) {
                    this.data.list.push(item);
                }
                this.data.loading = false;
            });
        } catch(e) {
            showToast(`${e}\n${e.stack}`);
            this.setState(()=>{
                this.data.loading = false;
            });
        }
    }

    async request(url) {
        let res = await fetch(url);
        let html = await res.text();
        let doc = HTMLParser.parse(html);
        let nodes = doc.querySelectorAll('.show-list > li');

        let results = [];
        for (let node of nodes) {
            let elem = node.querySelector('.play-img');
            let link = elem.querySelector('img');

            let item = {
                link: new URL(elem.getAttribute('href'), url).toString(),
                title: link.getAttribute('alt'),
                picture: link.getAttribute('src'),
                subtitle: node.querySelector('.play-txt .fn-right').text.trim(),
            };
            results.push(item);
        }
        return results;
    }
}

module.exports = SearchController;