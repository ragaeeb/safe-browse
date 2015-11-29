import bb.cascades 1.3

TextInputActionItem
{
    id: browseAction
    hintText: qsTr("Enter URL...") + Retranslate.onLanguageChanged
    input.submitKey: SubmitKey.Submit
    input.keyLayout: KeyLayout.Url
    content.flags: TextContentFlag.ActiveTextOff | TextContentFlag.EmoticonsOff
    input.submitKeyFocusBehavior: SubmitKeyFocusBehavior.Lose
    input.onSubmitted: {
        reporter.record("UrlSubmitted");
        
        var request = text.trim();
        if (request.length > 0)
        {
            if (request.indexOf("http://") != 0) {
                request = "http://" + request;
            }
            
            detailsView.url = request;
        }
    }
    
    onTextChanging: {
        showPlaceHolder = false;
    }
    
    onCreationCompleted: {
        if ( security.accountCreated() ) {
            tutorial.exec("addressBar", qsTr("Type the address of the website you wish to visit here."), HorizontalAlignment.Left, VerticalAlignment.Bottom, deviceUtils.du(10), 0, 0, deviceUtils.du(1), undefined, "r");
        }
    }
}