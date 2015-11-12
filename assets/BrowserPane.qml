import bb.cascades 1.2
import com.canadainc.data 1.0

NavigationPane
{
    id: navigationPane
    property variant target
    property bool showClose: false
    property alias currentProgress: browsePage.currentProgress
    property alias totalProgress: browsePage.totalProgress
    signal closeTab();
    
    onTargetChanged: {
        browsePage.webView.url = target;
    }
    
    function promptForAddress() {
        browsePage.browseField.requestFocus();
        browsePage.showPlaceHolder = true;
    }
    
    onShowCloseChanged: {
        if (showClose) {
            browsePage.addAction(closeAction);
        }
    }
    
    onPopTransitionEnded: {
        page.destroy();
    }
    
    function showBlockedPage()
    {
        var uri = browsePage.webView.url.toString();
        browsePage.webView.html = "<html><head><title>Blocked!</title><style>* { margin: 0px; padding 0px; }body { font-size: 48px; font-family: monospace; border: 1px solid #444; padding: 4px; }</style> </head> <body>Blocked: %1!</body></html>".arg(uri);
        helper.logBlocked(navigationPane, uri);
    }
    
    function onDataLoaded(id, data)
    {
        var mode = helper.mode;
        
        if ( id == QueryId.LookupDomain && ( (mode == "passive" && data.length > 0) || (mode == "controlled" && data.length == 0) ) ) {
            showBlockedPage();
        } else if (id == QueryId.LookupKeywords && data.length >= helper.threshold) {
            showBlockedPage();
        }
    }
    
    BrowserPage
    {
        id: browsePage
        
        webView.onLoadProgressChanged: {
            navigationPane.parent.unreadContentCount = 100-loadProgress;
        }
        
        webView.onUrlChanged: {
            helper.analyze(navigationPane, url);
        }
        
        webView.onTitleChanged: {
            navigationPane.parent.description = title;
            helper.analyzeKeywords(navigationPane, title);
        }
        
        actions: [
            ActionItem
            {
                title: qsTr("Pin to Homescreen") + Retranslate.onLanguageChanged
                imageSource: "images/menu/ic_pin.png"
                enabled: browsePage.webView.title.length > 0
                
                onTriggered: {
                    console.log("UserEvent: PinToHomeScreenTriggered");
                    
                    shortcut.active = true;
                    shortcut.object.defaultTitle = browsePage.webView.title;
                    shortcut.object.urlToPin = browsePage.webView.url;
                    shortcut.object.openPinPrompt();
                }
                
                attachedObjects: [
                    Delegate {
                        id: shortcut
                        active: false
                        source: "ShortcutHelper.qml"
                    }
                ]
            }
        ]
    }
    
    attachedObjects: [
        DeleteActionItem
        {
            id: closeAction
            imageSource: "images/menu/ic_close_tab.png"
            title: qsTr("Close Tab") + Retranslate.onLanguageChanged
            
            onTriggered: {
                console.log("UserEvent: CloseTabTriggered");
                closeTab();
            }
        }
    ]
}