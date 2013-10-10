import bb.cascades 1.0

Page
{
    actions: [
        ActionItem {
            title: qsTr("Open") + Retranslate.onLanguageChanged
            imageSource: "images/ic_parents.png"
            ActionBar.placement: ActionBarPlacement.OnBar

            onTriggered: {
                app.invokeSettingsApp();
            }
        }
    ]
    
    titleBar: SafeTitleBar {}
    
    ListView
    {
        id: listView

        verticalAlignment: VerticalAlignment.Fill
        horizontalAlignment: HorizontalAlignment.Fill
        leftPadding: 20
        rightPadding: 20

        dataModel: ArrayDataModel {
            id: adm
        }

        listItemComponents:
        [
            ListItemComponent
            {
                Container
                {
                    topPadding: 10; bottomPadding: 20
                    horizontalAlignment: HorizontalAlignment.Fill
                    verticalAlignment: VerticalAlignment.Fill

                    ImageView {
                        imageSource: ListItemData.imageSource
                        bottomMargin: 0
                    }
                    
                    Label {
                        topMargin: 0
                        text: ListItemData.text
                        multiline: true
                        textStyle.fontSize: FontSize.XSmall
                    }
                }
            }
        ]

        onCreationCompleted: {
            adm.append({
                    'text': "Swipe-down from the BB10 home screen and choose Settings. Then scroll down in the list and go to 'Security & Privacy'.",
                    'imageSource': "images/screenshots/0.png"
                });
            adm.append({
                    'text': "Select 'Parental Controls'.",
                    'imageSource': "images/screenshots/1.png"
                });
            adm.append({
                    'text': "Enable the parental controls toggle button.",
                    'imageSource': "images/screenshots/2.png"
                });
            adm.append({
                    'text': "Choose a password.",
                    'imageSource': "images/screenshots/3.png"
                });
            adm.append({
                    'text': "Disallow the browser toggle button.",
                    'imageSource': "images/screenshots/4.png"
                });
            adm.append({
                    'text': "Optional: For added security you might also want to disable the 'Remove Application' toggle button so that no one can delete this app and get rid of all your blocking settings.",
                    'imageSource': "images/screenshots/5.png"
                });
            adm.append({
                    'text': "Optional: For added security you might also want to disable the 'Install Application' toggle button so that no one can download additional web browsing apps.",
                    'imageSource': "images/screenshots/6.png"
                });
        }
    }
}