import bb.cascades 1.3
import bb.system 1.2

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
    
    function cleanUp() {}
    
    function setProgress(current, total)
    {
        progressIndicator.value = current;
        progressIndicator.toValue = total;
    }
    
    actions: [
        TextInputActionItem
        {
            id: browseAction
            hintText: qsTr("Enter URL...") + Retranslate.onLanguageChanged
            input.submitKey: SubmitKey.Submit
            input.keyLayout: KeyLayout.Url
            content.flags: TextContentFlag.ActiveTextOff | TextContentFlag.EmoticonsOff
            input.submitKeyFocusBehavior: SubmitKeyFocusBehavior.Lose
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
        },
        
        ActionItem {
            title: qsTr("Back") + Retranslate.onLanguageChanged
            imageSource: "images/menu/ic_back.png"
            enabled: detailsView.canGoBack
            ActionBar.placement: ActionBarPlacement.OnBar
            
            shortcuts: [
                SystemShortcut
                {
                    type: SystemShortcuts.PreviousSection
                    
                    onTriggered: {
                        reporter.record("GoBackShortcut");
                    }
                }
            ]
            
            onTriggered: {
                console.log("UserEvent: GoBack");
                reporter.record("GoBack");
                detailsView.goBack();
            }
        },
        
        ActionItem
        {
            title: qsTr("Forward") + Retranslate.onLanguageChanged
            imageSource: "images/menu/ic_forward.png"
            enabled: detailsView.canGoForward
            ActionBar.placement: ActionBarPlacement.OnBar
            
            shortcuts: [
                SystemShortcut {
                    type: SystemShortcuts.NextSection
                    
                    onTriggered: {
                        reporter.record("GoForwardShortcut");
                    }
                }
            ]
            
            onTriggered: {
                console.log("UserEvent: GoForward");
                reporter.record("GoForward");
                detailsView.goForward();
            }
        },
        
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
                }
            }
        }
    ]
    
    onActionMenuVisualStateChanged: {
        if (actionMenuVisualState == ActionMenuVisualState.VisibleFull) {
            tutorial.exec( "refresh", qsTr("Tap on the '%1' action to refresh the currently displayed page.").arg(refresh.title), HorizontalAlignment.Right, VerticalAlignment.Center, 0, ui.du(2), 0, 0, refresh.imageSource.toString() );
            tutorial.exec( "pin", qsTr("Tap on the 'Pin to Homescreen' action to go to add a shortcut to this website directly on your homescreen."), HorizontalAlignment.Right, VerticalAlignment.Center, 0, ui.du(2), 0, 0, "images/menu/ic_pin.png" );
        }
        
        reporter.record("AyatPageMenuOpened", actionMenuVisualState.toString());
    }
    
    onCreationCompleted: {
        if (!deviceUtils.isPhysicalKeyboardDevice) {
            addAction(jumpTop);
            addAction(jumpBottom);
        }
        
        tutorial.execActionBar("browserOverflow", qsTr("Tap here to open additional actions available for this page."), "o");
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
        }
    ]
}