import bb.cascades 1.0
import bb.system 1.0

NavigationPane
{
    id: navigationPane
    
    attachedObjects: [
        ComponentDefinition {
            id: definition
        }
    ]
    
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
    
    Menu.definition: MenuDefinition
    {
        settingsAction: SettingsActionItem
        {
            id: settingsAction
            property Page settingsPage
            
            onTriggered:
            {
                if (!settingsPage) {
                    definition.source = "SettingsPage.qml"
                    settingsPage = definition.createObject()
                }
                
                navigationPane.push(settingsPage);
            }
        }
        
        helpAction: HelpActionItem
        {
            id: helpAction
            property Page helpPage
            
            onTriggered:
            {
                if (!helpPage) {
                    definition.source = "HelpPage.qml"
                    helpPage = definition.createObject();
                }
                
                navigationPane.push(helpPage);
            }
        }
    }
    
    Page
    {
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
                    detailsView.reload();
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
                    settings.zoomToFitEnabled: true
                    settings.activeTextEnabled: true
                    horizontalAlignment: HorizontalAlignment.Fill
                    verticalAlignment: VerticalAlignment.Fill

                    onLoadProgressChanged: {
                        progressIndicator.value = loadProgress / 100.0
                    }
                    
                    onUrlChanged: {
                        var urlValue = url.toString();
                        
                        if ( urlValue.indexOf("http") == 0 )
                        {
                            var request = uriUtil.removeProtocol(urlValue); // http://a.m.google.com/abc.html -> a.m.google.com/abc.html
                            var slashIndex = request.indexOf("/");

                            if (slashIndex != -1) {
                                request = request.substring(0, slashIndex); // a.m.google.com
                            }

                            var lastDotIndex = request.lastIndexOf(".");
                            var subRequest = request.substring(0, lastDotIndex); // a.m.google

                            var secondLastDotIndex = subRequest.lastIndexOf(".");

                            if (secondLastDotIndex != -1) {
                                var lastToken = subRequest.substring(secondLastDotIndex + 1); // google
                                request = lastToken + request.substring(lastDotIndex);
                            }

                            var mode = persist.getValueFor("mode");
                            sql.query = "SELECT * FROM %1 WHERE uri=? LIMIT 1".arg(mode);
                            var params = [ request ];
                            sql.executePrepared(params, 20);

                            sql.query = "INSERT INTO logs (action,comment) VALUES ('%1',?)".arg("requested");
                            params = [ request ];
                            sql.executePrepared(params, 40);
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
                        if (id == 20) {
                            var mode = persist.getValueFor("mode");
                            
                            if ( (mode == "passive" && data.length > 0) || (mode == "controlled" && data.length == 0) ) {
                                html = "<html><head><title>Blocked!</title><style>* { margin: 0px; padding 0px; }body { font-size: 48px; font-family: monospace; border: 1px solid #444; padding: 4px; }</style> </head> <body>Blocked website!</body></html>"
                                
                                sql.query = "INSERT INTO logs (action,comment) VALUES ('%1',?)".arg("blocked");
                                sql.executePrepared( [ url.toString() ], 50 );
                            }
                        }
                    }
                    
                    onCreationCompleted: {
                        url = persist.getValueFor("home");
                        sql.dataLoaded.connect(onDataLoaded);
                    }
                    
                    attachedObjects: [
                        UriUtil {
                            id: uriUtil
                        }
                    ]
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