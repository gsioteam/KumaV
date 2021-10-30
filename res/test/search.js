
class SearchController extends Controller {

    load() {
        let str = localStorage['hints'];
        let hints = [];
        if (str) {
            hints = JSON.parse(str);
        }
        console.log(hints);
        this.data = {
            list: [],
            focus: false,
            hints: hints,
        };
    }

    onSearchClicked() {
        console.log("on clicked!");
    } 

    onTextChange(text) {
        console.log(`onChange ${text}`);
    }

    onTextSubmit(text) {
        console.log(`onSubmit ${text}`);
        this.setState(()=>{
            this.data.hints.push(text);
            localStorage['hints'] = JSON.stringify(this.data.hints);
        });
    }

    onTextFocus() {
        console.log("onFocus");
        this.setState(()=>{
            this.data.focus = true;
        });
    }

    onTextBlur() {
        console.log("onBlur");
        this.setState(()=>{
            this.data.focus = false;
        });
    }

    onPressed(index) {

    }

    onHintPressed(index) {

    }
}

module.exports = SearchController;