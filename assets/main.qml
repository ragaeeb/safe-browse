import bb.cascades 1.2

TabbedPane
{
    id: root
    activeTab: browseTab
    showTabsOnActionBar: false
    property variant target
    
    onTargetChanged: {
        activePane.target = target;
    }
    
    Menu.definition: CanadaIncMenu
    {
        id: menuDef
        help.imageSource: "images/menu/ic_help.png"
        help.title: qsTr("Help") + Retranslate.onLanguageChanged
        projectName: "safe-browse"
        settings.imageSource: "images/menu/ic_settings.png"
        settings.title: qsTr("Settings") + Retranslate.onLanguageChanged
        showSubmitLogs: true
    }
    
    Tab {
        id: newTab
        title: qsTr("New") + Retranslate.onLanguageChanged
        description: qsTr("New Tab") + Retranslate.onLanguageChanged
        imageSource: "images/tabs/ic_new_tab.png"
        
        onTriggered: {
            console.log("UserEvent: NewTabTriggered");
            
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
    
    function onClosed() {
        menuDef.settings.triggered();
    }
    
    function onReady()
    {
        if ( !security.accountCreated() )
        {
            definition.source = "SignupSheet.qml";
            var sheet = definition.createObject();
            sheet.closed.connect(onClosed);
            sheet.open();
        } else {
            if ( persist.tutorial( "tutorialSettings", qsTr("If you want to manage the list of websites that should be allowed or blocked, swipe-down from the top-bezel and go to Settings."), "asset:///images/menu/ic_settings.png" ) ) {}
            else if ( persist.tutorial( "tutorialPinHomeScreen", qsTr("To bookmark a page, you can choose 'Pin to Homescreen' from the menu."), "asset:///images/menu/ic_pin.png" ) ) {}
            else if ( persist.tutorial( "tutorialNewTab", qsTr("You can have more than one tab open! Swipe towards the right by dragging the menu on the left, and tap on 'New Tab' to open a new page to browse."), "asset:///images/tabs/ic_new_tab.png" ) ) {}
            else if ( persist.tutorial( "tutorialBrowse", qsTr("Tap on the Browse icon at the bottom to enter a new address to visit."), "asset:///images/ic_globe.png" ) ) {}
        }
    }
    
    onCreationCompleted: {
        app.initialize.connect(onReady);
    }
    
    attachedObjects: [
        ComponentDefinition {
            id: definition
        }
    ]
}