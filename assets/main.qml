import bb.cascades 1.0
import bb.system 1.0
import com.canadainc.data 1.0

NavigationPane
{
    id: navigationPane
    property alias target: detailsView.url
    
    attachedObjects: [
        ComponentDefinition {
            id: definition
        }
    ]
    
    Menu.definition: CanadaIncMenu {
        projectName: "safe-browse"
    }
    
    onPopTransitionEnded: {
        page.destroy();
    }
    
    onCreationCompleted: {
        if ( !security.accountCreated() ) {
            definition.source = "SignupSheet.qml";
            var sheet = definition.createObject();
            sheet.open();
            
            settingsAction.triggered();
            helpAction.triggered();
        }
    }
    
    Page
    {
		actionBarAutoHideBehavior: ActionBarAutoHideBehavior.HideOnScroll
    
        actions: [
            ActionItem {
                title: qsTr("Back") + Retranslate.onLanguageChanged
                imageSource: "images/ic_back.png"
                enabled: detailsView.canGoBack
                ActionBar.placement: ActionBarPlacement.OnBar

                onTriggered: {
                    detailsView.goBack();
                }
            },
            
            ActionItem {
                title: qsTr("Browse") + Retranslate.onLanguageChanged
                imageSource: "images/ic_globe.png"
                ActionBar.placement: ActionBarPlacement.OnBar

                onTriggered: {
                    prompt.show();
                }

                attachedObjects: [
                    SystemPrompt {
                        id: prompt
                        title: qsTr("Enter URL") + Retranslate.onLanguageChanged
                        body: qsTr("Enter the URL you want to browse.") + Retranslate.onLanguageChanged
                        confirmButton.label: qsTr("OK") + Retranslate.onLanguageChanged
                        cancelButton.label: qsTr("Cancel") + Retranslate.onLanguageChanged
                        inputField.defaultText: "http://www."

                        onFinished: {
                            if (result == SystemUiResult.ConfirmButtonSelection) {
                                var request = prompt.inputFieldTextEntry();
                                request = request.replace(/^\s+|\s+$/g, "");

                                if (request.indexOf("http://") != 0) {
                                    request = "http://" + request;
                                }

                                detailsView.url = request;
                            }
                        }
                    }
                ]
            },

            ActionItem {
                title: qsTr("Forward") + Retranslate.onLanguageChanged
                imageSource: "images/ic_forward.png"
                enabled: detailsView.canGoForward
                ActionBar.placement: ActionBarPlacement.OnBar

                onTriggered: {
                    detailsView.goForward();
                }
            },

            ActionItem {
                title: qsTr("Refresh") + Retranslate.onLanguageChanged
                imageSource: "images/ic_refresh.png"

                onTriggered: {
                	if (target == "local:///") {
                		detailsView.url = detailsView.requested;
                	} else {
                    	detailsView.reload();
                	}
                }
            }
        ]
        
        Container
        {
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

                WebView
                {
                    id: detailsView
                    property variant requested
                    settings.zoomToFitEnabled: true
                    settings.activeTextEnabled: true
                    horizontalAlignment: HorizontalAlignment.Fill
                    verticalAlignment: VerticalAlignment.Fill

                    onLoadProgressChanged: {
                        progressIndicator.value = loadProgress / 100.0
                    }
                    
                    onUrlChanged: {
                        var urlValue = url.toString();
                        
                        if ( urlValue.indexOf("http") == 0 || urlValue.indexOf("https") == 0 )
                        {
							var slashslash = urlValue.indexOf("//") + 2;
							var domain = urlValue.substring( slashslash, urlValue.indexOf("/", slashslash) );
							
							requested = url;
							app.analyze(domain);
                        }
                    }
                    
                    onLoadingChanged: {
                        if (loadRequest.status == WebLoadStatus.Started) {
                            progressIndicator.visible = true;
                            progressIndicator.state = ProgressIndicatorState.Progress;
                        } else if (loadRequest.status == WebLoadStatus.Succeeded) {
                            progressIndicator.visible = false;
                            progressIndicator.state = ProgressIndicatorState.Complete;
                        } else if (loadRequest.status == WebLoadStatus.Failed) {
                            html = "<html><head><title>Load Fail</title><style>* { margin: 0px; padding 0px; }body { font-size: 48px; font-family: monospace; border: 1px solid #444; padding: 4px; }</style> </head> <body>Loading failed! Please check your internet connection.</body></html>"
                            progressIndicator.visible = false;
                            progressIndicator.state = ProgressIndicatorState.Error;
                        }
                    }
                    
                    function onDataLoaded(id, data)
                    {
                        if (id == QueryId.LookupDomain) {
                            var mode = persist.getValueFor("mode");
                            
                            if ( (mode == "passive" && data.length > 0) || (mode == "controlled" && data.length == 0) ) {
                            	var uri = url.toString();
                                html = "<html><head><title>Blocked!</title><style>* { margin: 0px; padding 0px; }body { font-size: 48px; font-family: monospace; border: 1px solid #444; padding: 4px; }</style> </head> <body>Blocked: %1!</body></html>".arg(uri);
                                
                                app.logBlocked(uri);
                            }
                        }
                    }
                    
                    onCreationCompleted: {
                        sql.dataLoaded.connect(onDataLoaded);
                    }
                }
            }

            ProgressIndicator {
                id: progressIndicator
                horizontalAlignment: HorizontalAlignment.Center
                verticalAlignment: VerticalAlignment.Top
                visible: true
                value: 0
                fromValue: 0
                toValue: 1
                state: ProgressIndicatorState.Pause
                topMargin: 0; bottomMargin: 0; leftMargin: 0; rightMargin: 0;
            }
        }
    }
}