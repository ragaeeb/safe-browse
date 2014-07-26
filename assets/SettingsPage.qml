import bb.cascades 1.0
import bb.system 1.2
import com.canadainc.data 1.0

Page
{
    id: dashPage
    actionBarAutoHideBehavior: ActionBarAutoHideBehavior.HideOnScroll
    titleBar: SafeTitleBar {}
    
    function showSheet(sheetSource)
    {
        definition.source = sheetSource;
        var sheet = definition.createObject();
        sheet.open();
    }
    
    onCreationCompleted: {
        loginPrompt.show();
    }
    
    actions: [
        ActionItem
        {
            id: addAction
            imageSource: "images/ic_add.png"
            title: qsTr("Add") + Retranslate.onLanguageChanged
            ActionBar.placement: 'Signature' in ActionBarPlacement ? ActionBarPlacement["Signature"] : ActionBarPlacement.OnBar
            
            shortcuts: [
                SystemShortcut {
                    type: SystemShortcuts.CreateNew
                }
            ]
            
            onTriggered: {
                console.log("UserEvent: AddSiteTriggered");
                addPrompt.show();
            }
            
            attachedObjects: [
                SystemPrompt
                {
                    id: addPrompt
                    title: qsTr("Enter URL") + Retranslate.onLanguageChanged
                    body: qsTr("Enter the host address (ie: youtube.com). Don't append any http:// or www.") + Retranslate.onLanguageChanged
                    confirmButton.label: qsTr("OK") + Retranslate.onLanguageChanged
                    cancelButton.label: qsTr("Cancel") + Retranslate.onLanguageChanged
                    inputField.emptyText: "youtube.com"
                    inputOptions: SystemUiInputOption.None
                    
                    onFinished: {
                        console.log( "UserEvent: NewAddressToBlockEntered", value, inputFieldTextEntry() );

                        if (value == SystemUiResult.ConfirmButtonSelection)
                        {
                            var request = inputFieldTextEntry().trim();
                            request = uriUtil.removeProtocol(request);
                            
                            helper.blockSite(listView, modeDropDown.selectedValue, request);
                        }
                    }
                }
            ]
        },
        
        ActionItem
        {
            imageSource: "images/ic_home.png"
            title: qsTr("Set Home") + Retranslate.onLanguageChanged
            ActionBar.placement: ActionBarPlacement.OnBar
            
            onTriggered: {
                console.log("UserEvent: SetHomeTriggered");
                homePrompt.showPrompt();
            }
            
            attachedObjects: [
                SystemPrompt
                {
                    id: homePrompt
                    title: qsTr("Enter URL") + Retranslate.onLanguageChanged
                    body: qsTr("Enter the homepage address (ie: http://learnaboutislam.co.uk)") + Retranslate.onLanguageChanged
                    confirmButton.label: qsTr("OK") + Retranslate.onLanguageChanged
                    cancelButton.label: qsTr("Cancel") + Retranslate.onLanguageChanged
                    inputField.emptyText: "http://canadainc.org"
                    inputOptions: SystemUiInputOption.None
                    
                    function showPrompt() {
                        inputField.defaultText = persist.getValueFor("home");
                        show();
                    }
                    
                    onFinished: {
                        console.log( "UserEvent: HomepageAddressEntered", value, inputFieldTextEntry() );
                        
                        if (result == SystemUiResult.ConfirmButtonSelection)
                        {
                            var request = inputFieldTextEntry();
                            
                            if ( request.indexOf("http://") != 0 ) {
                                request = "http://"+request;
                            }
                            
                            persist.saveValueFor("home", request);
                            persist.showToast( qsTr("Successfully set homepage to %1").arg(request), "", "asset:///images/ic_home.png" );
                        }
                    }
                }
            ]
        },
        
        ActionItem
        {
            imageSource: "images/ic_password.png"
            title: qsTr("Change Password") + Retranslate.onLanguageChanged
            
            onTriggered: {
                console.log("UserEvent: ChangePasswordTriggered");
                dashPage.showSheet("SignupSheet.qml");
            }
        },
        
        ActionItem
        {
            imageSource: "images/ic_logs.png"
            title: qsTr("View Logs") + Retranslate.onLanguageChanged
            
            shortcuts: [
                Shortcut {
                    key: qsTr("V") + Retranslate.onLanguageChanged
                }
            ]
            
            onTriggered: {
                console.log("UserEvent: ViewLogsTriggered");
                definition.source = "ViewLogsPage.qml";
                var page = definition.createObject();
                dashPage.parent.push(page);
            }
        },
        
        DeleteActionItem
        {
            imageSource: "images/menu/ic_clear_cache.png"
            title: qsTr("Clear Cache") + Retranslate.onLanguageChanged
            
            onTriggered: {
                console.log("UserEvent: ClearCacheTriggered");
                persist.clearCache();
            }
        }
    ]
    
    Container
    {
        id: guardianContainer
        opacity: 0
        
        attachedObjects: [
            ImagePaintDefinition {
                id: back
                imageSource: "images/background.png"
            }
        ]
        
        background: back.imagePaint
        verticalAlignment: VerticalAlignment.Fill
        horizontalAlignment: HorizontalAlignment.Fill
        leftPadding: 10; rightPadding: 10;
        
        PersistDropDown
        {
            id: modeDropDown
            key: "mode"
            title: qsTr("Browsing Mode") + Retranslate.onLanguageChanged
            
            Option {
                text: qsTr("Passive") + Retranslate.onLanguageChanged
                description: qsTr("Allow all sites except certain ones") + Retranslate.onLanguageChanged
                value: "passive"
                imageSource: "images/ic_passive.png"
            }
            
            Option {
                text: qsTr("Controlled") + Retranslate.onLanguageChanged
                description: qsTr("Block all sites except certain ones") + Retranslate.onLanguageChanged
                value: "controlled"
                imageSource: "images/ic_controlled.png"
            }
            
            onValueChanged: {
                if (diff)
                {
                    if (selectedValue == "passive") {
                        persist.showToast( qsTr("All websites will be allowed except the ones you choose to block."), "", "asset:///images/ic_passive.png" );
                    } else if (selectedValue == "controlled") {
                        persist.showToast( qsTr("All websites will be blocked except the ones you choose to allow."), "", "asset:///images/ic_controlled.png" );
                    }
                }
                
                helper.fetchAllBlocked(listView, selectedValue);
            }
        }
        
        Divider {
            topMargin: 0; bottomMargin: 0
        }
        
        EmptyDelegate
        {
            id: noElements
            graphic: "images/placeholder/blocked_empty.png"
            labelText: qsTr("There are no websites currently blocked. Tap here to add one.") + Retranslate.onLanguageChanged
            
            onImageTapped: {
                addAction.triggered();
            }
        }
        
        ListView
        {
            id: listView
            
            dataModel: ArrayDataModel {
                id: adm
            }
            
            listItemComponents:
            [
                ListItemComponent
                {
                    StandardListItem
                    {
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
                                        console.log("UserEvent: RemoveBlockedSite");
                                        rootItem.ListItem.view.remove(ListItemData);
                                    }
                                }
                            }
                        ]
                        
                        ListItem.onInitializedChanged: {
                            if (initialized) {
                                showAnim.play();
                            }
                        }
                        
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
                    }
                }
            ]
            
            function remove(ListItemData) {
                helper.unblockSite(listView, modeDropDown.selectedValue, ListItemData.uri);
            }
            
            function onDataLoaded(id, data)
            {
                if (id == QueryId.GetAll)
                {
                    adm.clear()
                    adm.append(data);
                    
                    listView.visible = !adm.isEmpty();
                    noElements.delegateActive = !listView.visible;
                } else if (id == QueryId.InsertEntry) {
                    helper.fetchAllBlocked(listView, modeDropDown.selectedValue);
                } else if (id == QueryId.DeleteEntry) {
                    helper.fetchAllBlocked(listView, modeDropDown.selectedValue);
                }
            }
        }
    }
    
    attachedObjects: [
        SystemPrompt
        {
            id: loginPrompt
            body: qsTr("Please enter your password:") + Retranslate.onLanguageChanged
            title: qsTr("Login") + Retranslate.onLanguageChanged
            inputOptions: SystemUiInputOption.None
            inputField.emptyText: qsTr("Password cannot be empty...") + Retranslate.onLanguageChanged
            inputField.maximumLength: 20
            inputField.inputMode: SystemUiInputMode.Password
            
            onFinished: {
                console.log( "UserEvent: PasswordEntered", value, inputFieldTextEntry() );
                
                if (value == SystemUiResult.ConfirmButtonSelection)
                {
                    var password = inputFieldTextEntry().trim();
                    var loggedIn = security.login(password);
                    
                    if (!loggedIn)
                    {
                        helper.logFailedLogin(listView, password);
                        persist.showToast( qsTr("Wrong password entered. Please try again."), "", "asset:///images/dropdown/set_password.png" );
                        dashPage.parent.pop();
                    } else {
                        guardianContainer.opacity = 1;
                    }
                } else {
                    dashPage.removeAllActions();
                    dashPage.parent.pop();
                }
            }
        },

        UriUtil {
            id: uriUtil
        }
    ]
}