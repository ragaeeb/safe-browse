import QtQuick 1.0
import bb.cascades 1.2

Page
{
    id: browsePage
    actionBarAutoHideBehavior: ActionBarAutoHideBehavior.HideOnScroll
    property alias webView: detailsView
    property alias currentProgress: progressIndicator.value
    property alias totalProgress: progressIndicator.toValue
    property alias browseField: browseAction
    property alias showPlaceHolder: placeHolder.delegateActive
    property alias webContainer: mainContainer.controls
    property alias blockerVisible: blocker.visible
    
    function cleanUp() {}
    
    function setProgress(current, total)
    {
        progressIndicator.value = current;
        progressIndicator.toValue = total;
    }
    
    actions: [
        ActionItem
        {
            id: refresh
            title: qsTr("Refresh") + Retranslate.onLanguageChanged
            imageSource: "images/menu/ic_refresh.png"
            
            shortcuts: [
                SystemShortcut {
                    type: SystemShortcuts.Reply
                    
                    onTriggered: {
                        reporter.record("RefreshShortcut");
                    }
                }
            ]
            
            onTriggered: {
                console.log("UserEvent: RefreshTriggered");
                reporter.record("RefreshTriggered");
                
                if ( detailsView.url.toString() != "local:///" ) {
                    detailsView.urlChanged(detailsView.url);
                    detailsView.reload();
                    webView.reload();
                }
            }
        }
    ]
    
    onActionMenuVisualStateChanged: {
        if (actionMenuVisualState == ActionMenuVisualState.VisibleFull)
        {
            tutorial.execOverFlow( "refresh", qsTr("Tap on the '%1' action to refresh the currently displayed page."), refresh );
            tutorial.exec( "pin", qsTr("Tap on the 'Pin to Homescreen' action to go to add a shortcut to this website directly on your homescreen."), HorizontalAlignment.Right, VerticalAlignment.Center, 0, tutorial.du(2), 0, 0, "images/menu/ic_pin.png" );
        }
        
        reporter.record("BrowserMenuOpened", actionMenuVisualState.toString());
    }
    
    onCreationCompleted: {
        if (!deviceUtils.isPhysicalKeyboardDevice)
        {
            addAction(jumpTop);
            addAction(jumpBottom);
        }
        
        if ('Compact' in ChromeVisibility) {
            actionBarVisibility = ChromeVisibility["Compact"];
        }
    }
    
    titleBar: TitleBar
    {
        kind: TitleBarKind.FreeForm
        scrollBehavior: TitleBarScrollBehavior.Sticky
        
        kindProperties: FreeFormTitleBarKindProperties
        {
            content: Container
            {
                leftPadding: 5; rightPadding: 5
                
                layout: StackLayout {
                    orientation: LayoutOrientation.LeftToRight
                }

                TextField
                {
                    id: browseAction
                    hintText: qsTr("Enter URL...") + Retranslate.onLanguageChanged
                    input.submitKey: SubmitKey.Submit
                    inputMode: TextFieldInputMode.Url
                    input.flags: TextInputFlag.AutoCapitalizationOff | TextInputFlag.AutoCorrectionOff | TextInputFlag.PredictionOff | TextInputFlag.SpellCheckOff | TextInputFlag.WordSubstitutionOff
                    content.flags: TextContentFlag.ActiveTextOff | TextContentFlag.EmoticonsOff
                    input.submitKeyFocusBehavior: SubmitKeyFocusBehavior.Lose
                    verticalAlignment: VerticalAlignment.Center
                    input.onSubmitted: {
                        reporter.record("UrlSubmitted");
                        
                        var request = text.trim();
                        if (request.length > 0)
                        {
                            if (request.indexOf("http://") != 0) {
                                request = "http://" + request;
                            }
                            
                            detailsView.url = request;
                        }
                    }
                    
                    onTextChanging: {
                        showPlaceHolder = false;
                    }
                    
                    layoutProperties: StackLayoutProperties {
                        spaceQuota: 0.9
                    }
                }
                
                ImageButton
                {
                    horizontalAlignment: HorizontalAlignment.Right
                    defaultImageSource: "images/menu/ic_back.png"
                    pressedImageSource: "images/menu/ic_back_pressed.png"
                    disabledImageSource: "images/menu/ic_back_disabled.png"
                    verticalAlignment: VerticalAlignment.Center
                    enabled: detailsView.canGoBack
                    
                    layoutProperties: StackLayoutProperties {
                        spaceQuota: 0.05
                    }
                    
                    onEnabledChanged: {
                        if (enabled) {
                            tutorial.exec("goBack", qsTr("Tap here to go back to the previous page."), HorizontalAlignment.Right, VerticalAlignment.Top, 0, tutorial.du(8), 0, tutorial.du(1) );
                        }
                    }
                    
                    onClicked: {
                        console.log("UserEvent: GoBack");
                        reporter.record("GoBack");
                        detailsView.goBack();
                    }
                }
                
                ImageButton
                {
                    horizontalAlignment: HorizontalAlignment.Right
                    defaultImageSource: "images/menu/ic_forward.png"
                    pressedImageSource: "images/menu/ic_forward_pressed.png"
                    disabledImageSource: "images/menu/ic_forward_disabled.png"
                    verticalAlignment: VerticalAlignment.Center
                    enabled: detailsView.canGoForward
                    
                    layoutProperties: StackLayoutProperties {
                        spaceQuota: 0.05
                    }
                    
                    onEnabledChanged: {
                        if (enabled) {
                            tutorial.exec("goForward", qsTr("Tap here to go forward to the page you visited after the previous one."), HorizontalAlignment.Right, VerticalAlignment.Top, 0, tutorial.du(2), 0, tutorial.du(1) );
                        }
                    }
                    
                    onClicked: {
                        console.log("UserEvent: GoForward");
                        reporter.record("GoForward");
                        detailsView.goForward();
                    }
                }
            }
        }
    }
    
    Container
    {
        id: mainContainer
        horizontalAlignment: HorizontalAlignment.Fill
        verticalAlignment: VerticalAlignment.Fill
        background: Color.White
        layout: DockLayout {}
        
        ScrollView
        {
            id: scrollView
            horizontalAlignment: HorizontalAlignment.Fill
            verticalAlignment: VerticalAlignment.Fill
            scrollViewProperties.scrollMode: ScrollMode.Both
            scrollViewProperties.pinchToZoomEnabled: true
            scrollViewProperties.initialScalingMethod: ScalingMethod.AspectFill
            scrollRole: ScrollRole.Main
            
            onTouch: {
                if ( event.isDown() ) {
                    titleBar.visibility = ChromeVisibility.Hidden;
                    browsePage.actionBarVisibility = ChromeVisibility.Hidden;
                } else if ( event.isUp() || event.isCancel() ) {
                    timer.restart();
                }
            }
            
            Container
            {
                horizontalAlignment: HorizontalAlignment.Fill
                verticalAlignment: VerticalAlignment.Fill
                
                OfflineDelegate {
                    delegateActive: !network.online
                }
                
                WebView
                {
                    id: detailsView
                    settings.zoomToFitEnabled: true
                    settings.activeTextEnabled: true
                    horizontalAlignment: HorizontalAlignment.Fill
                    verticalAlignment: VerticalAlignment.Fill
                    
                    onUrlChanged: {
                        var uri = url.toString();
                        
                        if ( uri.indexOf("local://") >= 0 ) {
                            browseAction.text = "";
                            browseAction.requestFocus();
                        } else {
                            browseAction.text = uri;
                        }
                    }
                    
                    onLoadProgressChanged: {
                        progressIndicator.value = loadProgress / 100.0
                    }
                    
                    onLoadingChanged: {
                        if (loadRequest.status == WebLoadStatus.Started) {
                            progressIndicator.visible = true;
                            progressIndicator.state = ProgressIndicatorState.Progress;
                            busy.delegateActive = true;
                        } else if (loadRequest.status == WebLoadStatus.Succeeded) {
                            progressIndicator.visible = false;
                            progressIndicator.state = ProgressIndicatorState.Complete;
                            busy.delegateActive = false;
                        } else if (loadRequest.status == WebLoadStatus.Failed) {
                            html = "<html><head><title>Load Fail</title><style>* { margin: 0px; padding 0px; }body { font-size: 48px; font-family: monospace; border: 1px solid #444; padding: 4px; }</style> </head> <body>Loading failed! Please check your internet connection.</body></html>"
                            progressIndicator.visible = false;
                            progressIndicator.state = ProgressIndicatorState.Error;
                            busy.delegateActive = false;
                        }
                    }
                }
            }
        }
        
        EmptyDelegate
        {
            id: placeHolder
            labelText: qsTr("Please enter a URL on the address bar below...") + Retranslate.onLanguageChanged
            graphic: "images/list/ic_browse.png"
            
            onImageTapped: {
                console.log("UserEvent: EnterUrlPlaceHolderTapped");
                reporter.record("EnterUrlPlaceHolderTapped");
                browseAction.requestFocus();
            }
        }
        
        ProgressControl
        {
            id: busy
            asset: "images/spinners/loading_site.png"
            verticalAlignment: VerticalAlignment.Bottom
            horizontalAlignment: HorizontalAlignment.Right
            maxHeight: 75
            maxWidth: 75
        }
        
        ProgressIndicator
        {
            id: progressIndicator
            horizontalAlignment: HorizontalAlignment.Center
            verticalAlignment: VerticalAlignment.Top
            visible: true
            value: 0
            fromValue: 0
            toValue: 1
            opacity: value
            state: ProgressIndicatorState.Pause
            topMargin: 0; bottomMargin: 0; leftMargin: 0; rightMargin: 0;
        }
        
        Container
        {
            id: blocker
            horizontalAlignment: HorizontalAlignment.Fill
            verticalAlignment: VerticalAlignment.Fill
            visible: false
        }
    }
    
    attachedObjects: [
        ActionItem
        {
            id: jumpTop
            title: qsTr("Top") + Retranslate.onLanguageChanged
            imageSource: "images/common/ic_top.png"
            ActionBar.placement: ActionBarPlacement.InOverflow
            
            onTriggered: {
                console.log("UserEvent: JumpToTopBrowser");
                reporter.record("JumpToTopBrowser");
                scrollView.scrollToPoint(0,0);
            }
        },
        
        ActionItem
        {
            id: jumpBottom
            title: qsTr("Bottom") + Retranslate.onLanguageChanged
            imageSource: "images/common/ic_bottom.png"
            ActionBar.placement: ActionBarPlacement.InOverflow
            
            onTriggered: {
                console.log("UserEvent: JumpToBottomBrowser");
                reporter.record("JumpToBottomBrowser");
                scrollView.scrollToPoint(0, Infinity);
            }
        },
        
        Timer {
            id: timer
            repeat: false
            interval: 2000
            
            onTriggered: {
                titleBar.visibility = ChromeVisibility.Default;
                browsePage.actionBarVisibility = ChromeVisibility.Default;
            }
        }
    ]
}