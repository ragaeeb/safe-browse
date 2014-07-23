import bb.cascades 1.2

TabbedPane
{
    id: root
    activeTab: browseTab
    showTabsOnActionBar: false
    
    Menu.definition: CanadaIncMenu
    {
        id: menuDef
        projectName: "safe-browse"
        showSubmitLogs: true
    }
    
    Tab {
        id: newTab
        title: qsTr("New") + Retranslate.onLanguageChanged
        description: qsTr("New Tab") + Retranslate.onLanguageChanged
        imageSource: "images/tabs/ic_new_tab.png"
        
        onTriggered: {
            var newDoc = newDefinition.createObject();
            root.add(newDoc);
            
            root.activeTab = newDoc;
            newDoc.triggered();
        }
        
        attachedObjects: [
            ComponentDefinition
            {
                id: newDefinition
                
                Tab {
                    id: newTabContent
                    title: qsTr("Tab %1").arg( root.count() )
                    description: qsTr("New") + Retranslate.onLanguageChanged
                    imageSource: "images/tabs/ic_globe.png"
                    delegateActivationPolicy: TabDelegateActivationPolicy.ActivateWhenSelected
                    
                    delegate: Delegate
                    {
                        source: "BrowserPane.qml"
                        
                        function onClose()
                        {
                            root.activeTab = browseTab;
                            browseTab.triggered();
                            root.remove(newTabContent);
                            newTabContent.destroy(1000);
                        }
                        
                        onObjectChanged: {
                            if (object) {
                                object.closeTab.connect(onClose);
                                object.showClose = true;
                                object.promptForAddress();
                            }
                        }
                    }
                }
            }
        ]
    }
    
    Tab
    {
        id: browseTab
        title: qsTr("Browse") + Retranslate.onLanguageChanged
        description: qsTr("Surf the web") + Retranslate.onLanguageChanged
        imageSource: "images/tabs/ic_globe.png"
        unreadContentCount: 0
        delegateActivationPolicy: TabDelegateActivationPolicy.ActivateWhenSelected
        
        onTriggered: {
            console.log("UserEvent: BrowseTab");
        }
        
        delegate: Delegate {
            source: "BrowserPane.qml"
        }
    }
    
    function onReady()
    {
        if ( !security.accountCreated() ) {
            definition.source = "SignupSheet.qml";
            var sheet = definition.createObject();
            sheet.open();
            
            settingsAction.triggered();
            helpAction.triggered();
        }
    }
    
    onCreationCompleted: {
        app.initialize.connect(onReady);
    }
}