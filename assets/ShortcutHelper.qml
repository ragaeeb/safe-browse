import bb.cascades 1.0
import bb.system 1.2

QtObject
{
    id: promptObject
    property string defaultTitle
    property variant urlToPin
    
    function openPinPrompt() {
        homePrompt.show();
    }
    
    onDefaultTitleChanged: {
        homePrompt.inputField.defaultText = defaultTitle;
    }
    
    property SystemPrompt homePrompt: SystemPrompt
    {
        cancelButton.label: qsTr("Cancel") + Retranslate.onLanguageChanged
        confirmButton.label: qsTr("Save") + Retranslate.onLanguageChanged
        body: qsTr("This will be the name of the shortcut that shows up in your home screen") + Retranslate.onLanguageChanged
        inputField.emptyText: qsTr("Enter a name for this shortcut") + Retranslate.onLanguageChanged
        inputField.maximumLength: 15
        title: qsTr("Enter name") + Retranslate.onLanguageChanged
        
        onFinished: {
            if (value == SystemUiResult.ConfirmButtonSelection)
            {
                console.log("UserEvent: HomePromptConfirm");
                var result = inputFieldTextEntry().trim();
                
                if (result.length > 0) {
                    console.log("UserEvent: HomePromptConfirm");
                    app.addToHomeScreen(result, urlToPin, "images/icon_shortcut.png");
                } else {
                    persist.showToast( qsTr("Invalid shortcut name entered"), "images/toast/error.png" );
                    reporter.record("InvalidShortcut");
                }
            } else {
                console.log("UserEvent: HomePromptCancel");
                reporter.record("HomePromptCancel");
            }
        }
    }
}