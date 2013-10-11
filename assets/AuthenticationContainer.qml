import bb.cascades 1.0
import QtQuick 1.0

Container
{
    verticalAlignment: VerticalAlignment.Fill
    horizontalAlignment: HorizontalAlignment.Fill
    visible: !security.authenticated
    topPadding: 10
    
    TextField {
        id: passwordField
        
        inputMode: TextFieldInputMode.Password
        horizontalAlignment: HorizontalAlignment.Fill
        verticalAlignment: VerticalAlignment.Center
        
        input.submitKey: SubmitKey.Submit
        
        input.onSubmitted: {
            loginButton.clicked();
        }
    }
    
    Button {
        id: loginButton
        text: qsTr("Login") + Retranslate.onLanguageChanged
        horizontalAlignment: HorizontalAlignment.Center
        
        onClicked: {
            var loggedIn = security.login(passwordField.text);
            
            if (!loggedIn) {
                sql.query = "INSERT INTO logs (action,comment) VALUES ('%1',?)".arg("failed_login");
                var params = [passwordField.text];
                sql.executePrepared(params, 10);
                
                persist.showToast( qsTr("Wrong password entered. Please try again.") );
                passwordField.resetText();
            }
        }
    }
    
    attachedObjects: [
        Timer {
            running: true
            interval: 250
            repeat: false
            
            onTriggered: {
                passwordField.requestFocus();
            }
        }
    ]
}