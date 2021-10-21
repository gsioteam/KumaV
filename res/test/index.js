class IndexController extends Controller {
    load() {
        this.data = {
            tabs: [
                {
                    "title": "首页",
                    "id": "home",
                    "url": "http://www.qimiqimi.co/"
                },
                {
                    "title": "新番连载",
                    "id": "xinfan",
                    "url": "http://www.qimiqimi.co/type/xinfan/page/{0}.html"
                },
                {
                    "title": "完结日漫",
                    "id": "riman",
                    "url": "http://www.qimiqimi.co/type/riman/page/{0}.html"
                },
                {
                    "title": "BD番组",
                    "id": "wuxiu",
                    "url": "http://www.qimiqimi.co/type/wuxiu/page/{0}.html"
                },
                {
                    "title": "热门国漫",
                    "id": "guoman",
                    "url": "http://www.qimiqimi.co/type/guoman/page/{0}.html"
                },
                {
                    "title": "剧场&OVA",
                    "id": "jcdm",
                    "url": "http://www.qimiqimi.co/type/jcdm/page/{0}.html"
                }
            ]
        };
    }
}

module.exports = IndexController;