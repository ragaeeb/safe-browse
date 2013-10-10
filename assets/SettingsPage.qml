import bb.cascades 1.0
import bb.system 1.0
import QtQuick 1.0

Page
{
    id: dashPage
    
    titleBar: SafeTitleBar {}
    
    Container
    {
        attachedObjects: [
            ImagePaintDefinition {
                id: back
                imageSource: "images/background.png"
            }
        ]
        
        background: back.imagePaint
        verticalAlignment: VerticalAlignment.Fill
        horizontalAlignment: HorizontalAlignment.Fill
        leftPadding: 20; rightPadding: 20;
        
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
        
        ControlDelegate
        {
            id: secretDelegate
            verticalAlignment: VerticalAlignment.Fill
            horizontalAlignment: HorizontalAlignment.Fill
            delegateActive: security.authenticated
            
            sourceComponent: ComponentDefinition
            {
                Container
                {
                    id: mainContainer
                    verticalAlignment: VerticalAlignment.Fill
                    horizontalAlignment: HorizontalAlignment.Fill
                    
                    function reload()
                    {
                        sql.query = "SELECT uri FROM %1".arg(modeDropDown.selectedValue);
                        sql.load(4);
                    }
                    
                    DropDown {
                        id: modeDropDown
                        title: qsTr("Browsing Mode") + Retranslate.onLanguageChanged
                        
                        Option {
                            text: qsTr("Passive") + Retranslate.onLanguageChanged
                            description: qsTr("Allow all sites except certain ones") + Retranslate.onLanguageChanged
                            value: "passive"
                        }
                        
                        Option {
                            text: qsTr("Controlled") + Retranslate.onLanguageChanged
                            description: qsTr("Block all sites except certain ones") + Retranslate.onLanguageChanged
                            value: "controlled"
                        }
                        
                        onCreationCompleted: {
                            var mode = persist.getValueFor("mode")
                            
                            for (var i = 0; i < options.length; i ++) {
                                if (options[i].value == mode) {
                                    options[i].selected = true
                                    break;
                                }
                            }
                        }
                        
                        onSelectedValueChanged: {
                            var changed = persist.saveValueFor("mode", selectedValue);
                            mainContainer.reload();
                            
                            if (changed)
                            {
                                if (selectedValue == "passive") {
                                    persist.showToast("All websites will be allowed except the ones you choose to block.") + Retranslate.onLanguageChanged
                                } else if (selectedValue == "controlled") {
                                    persist.showToast("All websites will be blocked except the ones you choose to allow.") + Retranslate.onLanguageChanged
                                }
                            }
                        }
                    }
                    
                    Divider {
                        topMargin: 0; bottomMargin: 0
                    }
                    
                    ListView
                    {
                        dataModel: ArrayDataModel {
                            id: adm
                        }
                        
                        listItemComponents:
                        [
                            ListItemComponent
                            {
                                StandardListItem {
                                    id: rootItem
                                    imageSource: "images/ic_browse.png";
                                    description: ListItemData.uri
                                    
                                    contextActions: [
                                        ActionSet {
                                            title: qsTr("Safe Browse") + Retranslate.onLanguageChanged;
                                            subtitle: rootItem.description;
                                            
                                            DeleteActionItem {
                                                title: qsTr("Remove") + Retranslate.onLanguageChanged
                                                
                                                onTriggered: {
                                                    rootItem.ListItem.view.remove(ListItemData);
                                                }
                                            }
                                        }
                                    ]
                                    
                                    animations: [
                                        ParallelAnimation
                                        {
                                            id: showAnim
                                            ScaleTransition
                                            {
                                                fromX: 0.8
                                                toX: 1
                                                fromY: 0.8
                                                toY: 1
                                                duration: 800
                                                easingCurve: StockCurve.ElasticOut
                                            }
                                            
                                            FadeTransition {
                                                fromOpacity: 0
                                                toOpacity: 1
                                                duration: 200
                                            }
                                            
                                            delay: rootItem.ListItem.indexInSection * 100
                                        }
                                    ]
                                    
                                    onCreationCompleted: {
                                        showAnim.play();
                                    }
                                }
                            }
                        ]
                        
                        function remove(ListItemData) {
                            sql.query = "DELETE FROM %1 WHERE uri=?".arg(modeDropDown.selectedValue);
                            var params = [ListItemData.uri];
                            sql.executePrepared(params, 3);
                            
                            mainContainer.reload();
                        }
                        
                        function onDataLoaded(id, data)
                        {
                            if (id == 4) {
                                adm.clear()
                                adm.append(data);
                            }
                        }
                        
                        onCreationCompleted: {
                            sql.dataLoaded.connect(onDataLoaded);
                        }
                    }
                    
                    onCreationCompleted: {
                        var changePassword = actionDefinition.createObject();
                        changePassword.title = qsTr("Change Password") + Retranslate.onLanguageChanged;
                        changePassword.imageSource = "images/ic_password.png";
                        changePassword.triggered.connect( function showPasswordSheet() {
                            dashPage.showSheet("SignupSheet.qml");
                        });
                        dashPage.addAction(changePassword, ActionBarPlacement.InOverflow);
                        
                        var viewLogs = actionDefinition.createObject();
                        viewLogs.title = qsTr("View Logs") + Retranslate.onLanguageChanged;
                        viewLogs.imageSource = "images/ic_logs.png";
                        viewLogs.triggered.connect( function showPasswordSheet() {
                            dashPage.showSheet("ViewLogsSheet.qml");
                        });
                        dashPage.addAction(viewLogs, ActionBarPlacement.InOverflow);
                        
                        var addSite = actionDefinition.createObject();
                        addSite.title = qsTr("Add") + Retranslate.onLanguageChanged;
                        addSite.imageSource = "images/ic_add.png";
                        addSite.triggered.connect(prompt.show);
                        dashPage.addAction(addSite, ActionBarPlacement.OnBar);

                        var setHome = actionDefinition.createObject();
                        setHome.title = qsTr("Set Home") + Retranslate.onLanguageChanged;
                        setHome.imageSource = "images/ic_home.png";
                        setHome.triggered.connect(homePrompt.showPrompt);
                        dashPage.addAction(setHome, ActionBarPlacement.OnBar);
                    }
                    
                    attachedObjects: [
                        SystemPrompt {
                            id: prompt
                            title: qsTr("Enter URL") + Retranslate.onLanguageChanged
                            body: qsTr("Enter the host address (ie: youtube.com). Don't append any http:// or www.") + Retranslate.onLanguageChanged
                            confirmButton.label: qsTr("OK") + Retranslate.onLanguageChanged
                            cancelButton.label: qsTr("Cancel") + Retranslate.onLanguageChanged
                            inputField.emptyText: "youtube.com"
                            
                            onFinished: {
                                if (result == SystemUiResult.ConfirmButtonSelection) {
                                    var request = inputFieldTextEntry();
                                    request = request.replace(/^\s+|\s+$/g, "");
                                    
                                    request = uriUtil.removeProtocol(request);
                                    
                                    sql.query = "INSERT INTO %1 (uri) VALUES (?)".arg(modeDropDown.selectedValue);
                                    var params = [request];
                                    sql.executePrepared(params, 5);
                                    
                                    mainContainer.reload();
                                }
                            }
                        },

                        SystemPrompt {
                            id: homePrompt
                            title: qsTr("Enter URL") + Retranslate.onLanguageChanged
                            body: qsTr("Enter the homepage address (ie: http://abdurrahman.org)") + Retranslate.onLanguageChanged
                            confirmButton.label: qsTr("OK") + Retranslate.onLanguageChanged
                            cancelButton.label: qsTr("Cancel") + Retranslate.onLanguageChanged
                            inputField.emptyText: "http://abdurrahman.org"
                            
                            function showPrompt() {
                                inputField.defaultText = persist.getValueFor("home");
                                show();
                            }

                            onFinished: {
                                if (result == SystemUiResult.ConfirmButtonSelection) {
                                    var request = inputFieldTextEntry();
                                    request = request.replace(/^\s+|\s+$/g, "");

                                    if ( request.indexOf("http://") != 0 ) {
									    request = "http://"+request;
                                    }

                                    persist.saveValueFor("home", request);
                                    persist.showToast( qsTr("Successfully set homepage to %1").arg(request) );
                                }
                            }
                        },

                        UriUtil {
                            id: uriUtil
                        }
                    ]
                }
            }
        }
    }
    
    function showSheet(sheetSource)
    {
        definition.source = sheetSource;
        var sheet = definition.createObject();
        sheet.open();
    }
    
    attachedObjects: [
        ComponentDefinition {
            id: definition
        },
        
        ComponentDefinition {
            id: actionDefinition
            ActionItem {}
        }
    ]
}