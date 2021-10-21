
class MainController extends Controller {

    load(data) {
        this.id = data.id;
        this.url = data.url;
        this.data = {
            list: [],
            loading: false,
        };
    }

    async onPressed(index) {
        var data = this.data.list[index];
        await this.navigateTo('picture', {
            data: {
                src: data.img
            }
        });
    }

    onRefresh() {
        this.setState(() => {
            this.data.loading = true;
        });
        setTimeout(() => {
            this.setState(() => {
                this.data.loading = false;
            });
        }, 5000);
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
        localStorage['']
    }

    async fetch(url) {
        let res = await fetch(url);
        let doc = HTMLParser.parse(await res.text());

        let titles = doc.querySelectorAll('.latest-tab-nav > ul > li');
        let cols = doc.querySelectorAll('.latest-tab-box .latest-item');

        let items = [];
        for (let i = 0; i < len; ++i) {
            let telem = titles[i];
            let item = glib.DataItem.new();
            item.type = glib.DataItem.Type.Header;
            item.title = telem.text;
            items.push(item);

            let celem = cols[i];
            let list = celem.querySelectorAll('.img-list > li');
            for (let node of list) {
                let link = node.querySelector('a.play-img');
                let img = link.querySelector('img');
                let item = {
                    title: link.attr('title'),
                    link: new URL(link.attr('href'), url).toString(),
                    picture: img.attr('src'),
                    subtitle: node.querySelector('.time').text,
                };
                items.push(item);
            }
        }
        return items;
    }
}

module.exports = MainController;