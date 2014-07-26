import bb.cascades 1.0
import com.canadainc.data 1.0

Page
{
    id: viewLogPage
    actionBarAutoHideBehavior: ActionBarAutoHideBehavior.HideOnScroll
    
    titleBar: TitleBar {
        title: qsTr("View Logs") + Retranslate.onLanguageChanged
    }
    
    actions: [
        DeleteActionItem {
            title: qsTr("Clear Logs") + Retranslate.onLanguageChanged
            
            onTriggered: {
                var result = persist.showBlockingDialog( qsTr("Confirmation"), qsTr("Are you sure you want to clear all logs?") );
                
                if (result) {
                    helper.clearAllLogs(viewLogPage);
                    adm.clear();
                    noElements.delegateActive = true;
                }
            }
        }
    ]
    
    Container
    {
        horizontalAlignment: HorizontalAlignment.Fill
        verticalAlignment: VerticalAlignment.Fill
        
        DropDown
        {
            id: actionDropDown
            horizontalAlignment: HorizontalAlignment.Fill
            title: qsTr("Action") + Retranslate.onLanguageChanged
            selectedOption: allFilter
            
            Option {
                id: allFilter
                text: qsTr("All") + Retranslate.onLanguageChanged
                description: qsTr("Show All Activity") + Retranslate.onLanguageChanged
                imageSource: "images/dropdown/ic_logs_all.png"
                value: ""
            }
            
            Option {
                id: loginFilter
                text: qsTr("Authentication") + Retranslate.onLanguageChanged
                description: qsTr("Show Only Login Activity") + Retranslate.onLanguageChanged
                imageSource: "images/dropdown/ic_logs_authentication.png"
                value: "failed_login"
            }
            
            Option {
                id: browsingFilter
                text: qsTr("Browsing") + Retranslate.onLanguageChanged
                description: qsTr("Show Only Browsing Activity") + Retranslate.onLanguageChanged
                imageSource: "images/dropdown/ic_logs_browse.png"
                value: "requested"
            }
            
            Option {
                id: blockedFilter
                text: qsTr("Blocked") + Retranslate.onLanguageChanged
                description: qsTr("Show Only Browsing Activity") + Retranslate.onLanguageChanged
                imageSource: "images/dropdown/ic_logs_blocked.png"
                value: "blocked"
            }
            
            onSelectedValueChanged: {
                helper.fetchAllLogs(listView, selectedValue);
            }
        }
        
        EmptyDelegate
        {
            id: noElements
            graphic: "images/placeholder/logs_empty.png"
            labelText: qsTr("There is not activity currently recorded.") + Retranslate.onLanguageChanged
        }
        
        ListView
        {
            id: listView
            property variant localization: app
            verticalAlignment: VerticalAlignment.Fill
            horizontalAlignment: HorizontalAlignment.Fill
            
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
                    
                    LogListItem
                    {
                        imageSource: "images/ic_password.png";
                        title: qsTr("Failed Login") + Retranslate.onLanguageChanged
                        description: qsTr("Attempted login with '%1'").arg(ListItemData.comment)
                    }
                },
                
                ListItemComponent
                {
                    type: "requested"
                    
                    LogListItem {
                        imageSource: "images/ic_browse.png";
                        title: qsTr("Requested") + Retranslate.onLanguageChanged
                    }
                },
                
                ListItemComponent
                {
                    type: "blocked"
                    
                    LogListItem {
                        imageSource: "images/ic_block.png"
                        title: qsTr("Blocked") + Retranslate.onLanguageChanged
                    }
                }
            ]
            
            function onDataLoaded(id, data)
            {
                if (id == QueryId.GetLogs)
                {
                    adm.clear()
                    adm.append(data);
                    
                    listView.visible = !adm.isEmpty();
                    noElements.delegateActive = !listView.visible;
                }
            }
        }
    }
}