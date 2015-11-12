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
                var request = text.trim();
                if (request.length > 0)
                {
                    if (request.indexOf("http://") != 0) {
                        request = "http://" + request;
                    }
                    
                    detailsView.url = request;
                }
            }
        },
        
        ActionItem {
            title: qsTr("Back") + Retranslate.onLanguageChanged
            imageSource: "images/menu/ic_back.png"
            enabled: detailsView.canGoBack
            ActionBar.placement: ActionBarPlacement.OnBar
            
            shortcuts: [
                SystemShortcut {
                    type: SystemShortcuts.PreviousSection
                }
            ]
            
            onTriggered: {
                console.log("UserEvent: GoBack");
                detailsView.goBack();
            }
        },
        
        ActionItem {
            title: qsTr("Forward") + Retranslate.onLanguageChanged
            imageSource: "images/menu/ic_forward.png"
            enabled: detailsView.canGoForward
            ActionBar.placement: ActionBarPlacement.OnBar
            
            shortcuts: [
                SystemShortcut {
                    type: SystemShortcuts.NextSection
                }
            ]
            
            onTriggered: {
                console.log("UserEvent: GoForward");
                detailsView.goForward();
            }
        },
        
        ActionItem {
            title: qsTr("Refresh") + Retranslate.onLanguageChanged
            imageSource: "images/menu/ic_refresh.png"
            
            shortcuts: [
                SystemShortcut {
                    type: SystemShortcuts.Reply
                }
            ]
            
            onTriggered: {
                console.log("UserEvent: RefreshTriggered");
                
                if ( detailsView.url.toString() != "local:///" ) {
                    detailsView.urlChanged(detailsView.url);
                }
            }
        }
    ]
    
    onCreationCompleted: {
        if (!deviceUtils.isPhysicalKeyboardDevice) {
            addAction(jumpTop);
            addAction(jumpBottom);
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
            graphic: "images/ic_browse.png"
            
            onImageTapped: {
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
            imageSource: "images/menu/ic_top.png"
            ActionBar.placement: ActionBarPlacement.InOverflow
            
            onTriggered: {
                console.log("UserEvent: JumpToTopBrowser");
                scrollView.scrollToPoint(0,0);
            }
        },
        
        ActionItem
        {
            id: jumpBottom
            title: qsTr("Bottom") + Retranslate.onLanguageChanged
            imageSource: "images/menu/ic_bottom.png"
            ActionBar.placement: ActionBarPlacement.InOverflow
            
            onTriggered: {
                console.log("UserEvent: JumpToBottomBrowser");
                scrollView.scrollToPoint(0, Infinity);
            }
        }
    ]
}