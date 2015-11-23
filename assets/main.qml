import bb.cascades 1.3

TabbedPane
{
    id: root
    showTabsOnActionBar: false
    property variant target
    
    onTargetChanged: {
        if (target && browseTab.delegateActivationPolicy == TabDelegateActivationPolicy.ActivateWhenSelected) { // already initialized, and user decides to open another shortcut from home screen
            newDefinition.targetUrl = target;
            newTab.triggered();
        }
    }
    
    function onSidebarVisualStateChanged()
    {
        sidebarStateChanged.disconnect(onSidebarVisualStateChanged);

        tutorial.exec("tabsNew", qsTr("To browse a website in a separate tab, tap on the '%1' tab.").arg(newTab.title), HorizontalAlignment.Left, VerticalAlignment.Center, ui.du(3), 0, 0, ui.du(3) );

        reporter.record( "TabbedPaneExpanded", root.sidebarVisualState.toString() );
    }
    
    Menu.definition: CanadaIncMenu
    {
        id: menuDef
        bbWorldID: "31243891"
        projectName: "safe-browse"
        
        function onClosed() {
            menuDef.settings.triggered();
        }
        
        onFinished: {
            if ( !security.accountCreated() )
            {
                definition.source = "SignupSheet.qml";
                var sheet = definition.createObject();
                sheet.closed.connect(onClosed);
                sheet.open();
                
                tutorial.execCentered("adminPassword", qsTr("You are required to set an administrator password. This is going to be needed everytime you want to access the %1 settings to change the filtering rules and other administrative tasks.").arg(Application.applicationName), "images/ic_password.png");
            } else {
                tutorial.execAppMenu();
                tutorial.execActionBar("expandTabs", qsTr("Tap here to expand the tabs to be able to browse on more than one website at the same time."), "b" );
            }
            
            browseTab.delegateActivationPolicy = TabDelegateActivationPolicy.ActivateWhenSelected;
            activeTab = browseTab;
            
            if (target) {
                activePane.target = target;
            }
            
            sidebarStateChanged.connect(onSidebarVisualStateChanged);
        }
    }
    
    Tab {
        id: newTab
        title: qsTr("New") + Retranslate.onLanguageChanged
        description: qsTr("New Tab") + Retranslate.onLanguageChanged
        imageSource: "images/tabs/ic_new_tab.png"
        delegateActivationPolicy: TabDelegateActivationPolicy.None
        
        onTriggered: {
            console.log("UserEvent: NewTabTriggered");
            reporter.record("NewTabTriggered");
            
            var newDoc = newDefinition.createObject();
            root.add(newDoc);
            
            root.activeTab = newDoc;
            newDoc.triggered();
        }
        
        attachedObjects: [
            ComponentDefinition
            {
                id: newDefinition
                property variant targetUrl
                
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
                            if (object)
                            {
                                object.closeTab.connect(onClose);
                                object.showClose = true;
                                
                                if (newDefinition.targetUrl) {
                                    object.target = newDefinition.targetUrl;
                                    newDefinition.targetUrl = undefined;
                                } else {
                                    object.promptForAddress();
                                }
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
        delegateActivationPolicy: TabDelegateActivationPolicy.None
        
        onTriggered: {
            console.log("UserEvent: BrowseTab");
            reporter.record("BrowseTab");
        }
        
        delegate: Delegate {
            source: "BrowserPane.qml"
        }
    }
    
    attachedObjects: [
        ComponentDefinition {
            id: definition
        }
    ]
}