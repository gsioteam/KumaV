
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
            text: ''
        };
    }

    makeURL(word, page) {
        return baseURL.replace('{0}', glib.Encoder.urlEncode(this.key)).replace('{1}', page + 1);
    }

    onSearchClicked() {
        this.onTextSubmit(this.data.text);
    } 

    onTextChange(text) {
        this.data.text = text;
    }

    onTextSubmit(text) {
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

            this.load();
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

    }

    onHintPressed(index) {
        let hint = this.data.hints[index];
        if (hint) {
            this.setState(()=>{
                this.data.text = hint;
                this.findElement('input').submit();
            });
        }
    }

    load(url) {

    }
}

module.exports = SearchController;