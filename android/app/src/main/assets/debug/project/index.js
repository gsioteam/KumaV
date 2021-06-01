
const {Collection} = require('./collection');

function makeItem(node, pageUrl) {
    let item = glib.DataItem.new();
    let link = node.querySelector('.card-body > a');
    item.title = link.text.trim();
    let url = link.attr('href');
    let idx = url.indexOf('#');
    if (idx >= 0) {
        url = url.substr(0, idx);
    }
    item.link = pageUrl.href(url);
    item.picture = pageUrl.href(node.querySelector('img').attr('data-src'));
    
    let subtitle = '';
    let last = node.querySelectorAll('.card-img-overlay a');
    if (last.length > 0) {
        subtitle += last[0].text + ' ';
    }
    let divs = node.querySelectorAll('.card-body > div');
    if (divs.length > 0) {
        subtitle += divs[divs.length - 1].text;
    }
    item.subtitle = subtitle;

    return item;
}

class HomeCollection extends Collection {

    reload(_, cb) {
        let pageUrl = new PageURL(this.url);
        this.fetch(this.url).then((doc)=>{
            let list = doc.querySelectorAll('.panel-body');

            let items = [];
            for (let panel of list) {
                let nodes = panel.querySelectorAll('ul > li > .card');
                if (nodes.length == 0) continue;
                let arr = panel.querySelector('.panel-title').text.trim().split(' ');
                arr = arr[arr.length - 1].split('\n')
                let title = arr[arr.length - 1];
                let item = glib.DataItem.new();
                item.type = glib.DataItem.Type.Header;
                item.title = title;
                items.push(item);

                for (let node of nodes) {
                    items.push(makeItem(node, pageUrl));
                }
            }
            this.setData(items);
            cb.apply(null);
        }).catch((err)=>{
            if (err instanceof Error) {
                console.log("Err " + err.message + " stack " + err.stack);
                err = glib.Error.new(305, err.message);
            }
            cb.apply(err);
        });
        return true;
    }
}

class CategoryCollection extends Collection {

    constructor(data) {
        super(data);
        this.page = 0;
    }

    async fetch(url) {
        let pageUrl = new PageURL(url);

        let doc = await super.fetch(url);
        let nodes = doc.querySelectorAll('ul > li > .card');

        let items = [];
        for (let node of nodes) {
            items.push(makeItem(node, pageUrl));
        }
        return items;
    }

    makeURL(page) {
        if (this.url.indexOf('{0}') == -1) return this.url;
        return this.url.replace('{0}', page + 1);
    }

    reload(_, cb) {
        let page = 0;
        this.fetch(this.makeURL(page)).then((results)=>{
            this.page = page;
            this.setData(results);
            cb.apply(null);
        }).catch(function(err) {
            if (err instanceof Error) 
                err = glib.Error.new(305, err.message);
            cb.apply(err);
        });
        return true;
    }

    loadMore(cb) {
        if (this.url.indexOf('{0}') == -1) return false;
        let page = this.page + 1;
        this.fetch(this.makeURL(page)).then((results)=>{
            this.page = page;
            this.appendData(results);
            cb.apply(null);
        }).catch(function(err) {
            if (err instanceof Error) 
                err = glib.Error.new(305, err.message);
            cb.apply(err);
        });
        return true;
    }
}

module.exports = function(info) {
    let data = info.toObject();
    if (data.id === 'home') 
        return HomeCollection.new(data);
    else return CategoryCollection.new(data);
};
