import bb.cascades 1.2
import bb.system 1.2

ActionItem
{
    title: qsTr("Browse") + Retranslate.onLanguageChanged
    imageSource: "images/ic_globe.png"
    ActionBar.placement: 'Signature' in ActionBarPlacement ? ActionBarPlacement["Signature"] : ActionBarPlacement.OnBar
    property string text // just for a sake of dual compatibility
    
    onTriggered: {
        console.log("UserEvent: Browse");
        prompt.show();
    }
    
    function requestFocus() {
        prompt.show();
    }
    
    attachedObjects: [
        SystemPrompt {
            id: prompt
            title: qsTr("Enter URL") + Retranslate.onLanguageChanged
            body: qsTr("Enter the URL you want to browse.") + Retranslate.onLanguageChanged
            confirmButton.label: qsTr("OK") + Retranslate.onLanguageChanged
            cancelButton.label: qsTr("Cancel") + Retranslate.onLanguageChanged
            inputField.defaultText: "http://www."
            inputOptions: SystemUiInputOption.None
            inputField.emptyText: qsTr("URL cannot be empty...") + Retranslate.onLanguageChanged
            
            onFinished: {
                showPlaceHolder = false;
                
                if (value == SystemUiResult.ConfirmButtonSelection)
                {
                    reporter.record("UrlSubmitted");
                    console.log( "UserEvent: UrlEnteredPrompt", value, prompt.inputFieldTextEntry() );
                    var request = prompt.inputFieldTextEntry().trim();
                    
                    if (request.indexOf("http://") != 0) {
                        request = "http://" + request;
                    }
                    
                    detailsView.url = request;
                }
            }
        }
    ]
}