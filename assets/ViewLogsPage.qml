import bb.cascades 1.0
import com.canadainc.data 1.0

Page
{
    id: viewLogPage
    actionBarAutoHideBehavior: ActionBarAutoHideBehavior.HideOnScroll
    
    onCreationCompleted: {
        deviceUtils.attachTopBottomKeys(viewLogPage, listView);
    }
    
    titleBar: TitleBar
    {
        kind: TitleBarKind.Segmented

        options: [
            Option {
                id: allFilter
                text: qsTr("All") + Retranslate.onLanguageChanged
                description: qsTr("Show All Activity") + Retranslate.onLanguageChanged
                imageSource: "images/dropdown/ic_logs_all.png"
                value: ""
            },
            
            Option {
                id: loginFilter
                text: qsTr("Authentication") + Retranslate.onLanguageChanged
                description: qsTr("Show Only Login Activity") + Retranslate.onLanguageChanged
                imageSource: "images/dropdown/ic_logs_authentication.png"
                value: "failed_login"
            },
            
            Option {
                id: browsingFilter
                text: qsTr("Browsing") + Retranslate.onLanguageChanged
                description: qsTr("Show Only Browsing Activity") + Retranslate.onLanguageChanged
                imageSource: "images/dropdown/ic_logs_browse.png"
                value: "requested"
            },
            
            Option {
                id: blockedFilter
                text: qsTr("Blocked") + Retranslate.onLanguageChanged
                description: qsTr("Show Only Browsing Activity") + Retranslate.onLanguageChanged
                imageSource: "images/dropdown/ic_logs_blocked.png"
                value: "blocked"
            }
        ]
        
        onSelectedValueChanged: {
            console.log("UserEvent: ViewLogMode", selectedValue);
            reporter.record("ViewLogMode", selectedValue);
            helper.fetchAllLogs(listView, selectedValue);
        }
    }
    
    actions: [
        DeleteActionItem
        {
            id: clearLogsAction
            imageSource: "images/menu/ic_clear_logs.png"
            title: qsTr("Clear Logs") + Retranslate.onLanguageChanged
            enabled: listView.visible
            
            function onFinished(ok)
            {
                if (ok)
                {
                    reporter.record("ClearLogsConfirmed");
                    helper.clearAllLogs(viewLogPage);
                    adm.clear();
                    noElements.delegateActive = true;
                }
            }
            
            onTriggered: {
                console.log("UserEvent: ClearLogs");
                reporter.record("ClearLogs");
                persist.showDialog( clearLogsAction, qsTr("Confirmation"), qsTr("Are you sure you want to clear all logs?") );
            }
        }
    ]
    
    Container
    {
        horizontalAlignment: HorizontalAlignment.Fill
        verticalAlignment: VerticalAlignment.Fill
        
        EmptyDelegate
        {
            id: noElements
            graphic: "images/placeholder/logs_empty.png"
            labelText: qsTr("There is not activity currently recorded.") + Retranslate.onLanguageChanged
        }
        
        ListView
        {
            id: listView
            scrollRole: ScrollRole.Main
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