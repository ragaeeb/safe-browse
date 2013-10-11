import bb.cascades 1.0
import bb.system 1.0
import com.canadainc.data 1.0

Page
{
    id: dashPage
    actionBarAutoHideBehavior: ActionBarAutoHideBehavior.HideOnScroll
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
        
        AuthenticationContainer {}
        
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
                        sql.load(QueryId.GetAll);
                    }
                    
                    BrowsingModeDropDown
                    {
                        id: modeDropDown
                        
                        onSelectedValueChanged: {
                            mainContainer.reload();
                        }
                    }
                    
                    Divider {
                        topMargin: 0; bottomMargin: 0
                    }
                    
                    EntriesListView {}
                    
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
                                    request = uriUtil.removeProtocol(request);
                                    
                                    sql.query = "INSERT INTO %1 (uri) VALUES (?)".arg(modeDropDown.selectedValue);
                                    var params = [request];
                                    sql.executePrepared(params, QueryId.InsertEntry);
                                    
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
                                    request = uriUtil.removeProtocol(request);

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