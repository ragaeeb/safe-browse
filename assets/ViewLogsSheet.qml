import bb.cascades 1.0
import bb.system 1.0

Sheet
{
    id: root
    
    Page
    {
        titleBar: TitleBar
        {
            title: qsTr("View Logs") + Retranslate.onLanguageChanged
            
            dismissAction: ActionItem {
                title: qsTr("Close") + Retranslate.onLanguageChanged
                
                onTriggered: {
                    root.close();                
                }
            }
        }
        
        actions: [
            DeleteActionItem {
                title: qsTr("Clear Logs") + Retranslate.onLanguageChanged
                
                onTriggered: {
                    prompt.show();
                }
                
                attachedObjects: [
                    SystemDialog {
                        id: prompt
                        title: qsTr("Confirmation") + Retranslate.onLanguageChanged
                        body: qsTr("Are you sure you want to clear all logs?") + Retranslate.onLanguageChanged
                        confirmButton.label: qsTr("OK") + Retranslate.onLanguageChanged
                        cancelButton.label: qsTr("Cancel") + Retranslate.onLanguageChanged
                        
                        onFinished: {
                            if (result == SystemUiResult.ConfirmButtonSelection) {
                                sql.query = "DELETE from logs";
                                sql.load(2);
                                listView.reload();
                                
                                persist.showToast( qsTr("Cleared log!") );
                            }
                        }
                    }
                ]
            }
        ]
        
        ListView
        {
            id: listView
            property variant localization: localizer
            
            verticalAlignment: VerticalAlignment.Fill
            horizontalAlignment: HorizontalAlignment.Fill
            leftPadding: 20; rightPadding: 20;
            
            dataModel: ArrayDataModel {
                id: adm
            }
            
            function itemType(data, indexPath) {
                return data.action;
            }
            
            listItemComponents:
            [
                ListItemComponent
                {
                    type: "failed_login"
                    StandardListItem {
                        imageSource: "images/ic_password.png";
                        title: qsTr("Failed Login") + Retranslate.onLanguageChanged
                        description: qsTr("Attempted login with '%1'").arg(ListItemData.comment)
                        status: ListItem.view.localization.renderStandardTime(ListItemData.timestamp);
                    }
                },
                
                ListItemComponent
                {
                    type: "requested"
                    StandardListItem {
                        imageSource: "images/ic_browse.png";
                        title: qsTr("Requested") + Retranslate.onLanguageChanged
                        description: ListItemData.comment
                        status: ListItem.view.localization.renderStandardTime(ListItemData.timestamp);
                    }
                },

                ListItemComponent {
                    type: "blocked"
                    StandardListItem {
                        imageSource: "images/ic_block.png"
                        title: qsTr("Blocked") + Retranslate.onLanguageChanged
                        description: ListItemData.comment
                        status: ListItem.view.localization.renderStandardTime(ListItemData.timestamp)
                    }
                }
            ]
            
            leadingVisual: DropDown {
                id: actionDropDown
                horizontalAlignment: HorizontalAlignment.Fill
                title: qsTr("Action") + Retranslate.onLanguageChanged
                
                Option {
                    id: allFilter
                    text: qsTr("All") + Retranslate.onLanguageChanged
                    description: qsTr("Show All Activity") + Retranslate.onLanguageChanged
                    selected: true
                }
                
                Option {
                    id: loginFilter
                    text: qsTr("Authentication") + Retranslate.onLanguageChanged
                    description: qsTr("Show Only Login Activity") + Retranslate.onLanguageChanged
                    value: "failed_login"
                }
                
                Option {
                    id: browsingFilter
                    text: qsTr("Browsing") + Retranslate.onLanguageChanged
                    description: qsTr("Show Only Browsing Activity") + Retranslate.onLanguageChanged
                    value: "requested"
                }
                
                onSelectedOptionChanged:
                {
                    var value = selectedOption.value;
                    
                    if (value) {
                        sql.query = "SELECT * from logs WHERE action='%1'".arg(value);
                    } else {
                        sql.query = "SELECT * from logs";
                    }
                    
                    sql.load(1);
                }
            }
            
            function onDataLoaded(id, data)
            {
                if (id == 1) {
                    adm.clear()
                    adm.append(data);
                }
            }
            
            function reload() {
                actionDropDown.selectedOptionChanged(actionDropDown.selectedOption);
            }
            
            onCreationCompleted: {
                sql.dataLoaded.connect(onDataLoaded);
                reload();
            }
        }
    }
    
    onClosed: {
        destroy();
    }    
}