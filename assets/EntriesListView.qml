import bb.cascades 1.0
import com.canadainc.data 1.0

ListView
{
    dataModel: ArrayDataModel {
        id: adm
    }
    
    listItemComponents:
    [
        ListItemComponent
        {
            StandardListItem {
                id: rootItem
                imageSource: "images/ic_browse.png";
                description: ListItemData.uri
                
                contextActions: [
                    ActionSet {
                        title: qsTr("Safe Browse") + Retranslate.onLanguageChanged;
                        subtitle: rootItem.description;
                        
                        DeleteActionItem {
                            title: qsTr("Remove") + Retranslate.onLanguageChanged
                            
                            onTriggered: {
                                rootItem.ListItem.view.remove(ListItemData);
                            }
                        }
                    }
                ]
                
                animations: [
                    ParallelAnimation
                    {
                        id: showAnim
                        ScaleTransition
                        {
                            fromX: 0.8
                            toX: 1
                            fromY: 0.8
                            toY: 1
                            duration: 800
                            easingCurve: StockCurve.ElasticOut
                        }
                        
                        FadeTransition {
                            fromOpacity: 0
                            toOpacity: 1
                            duration: 200
                        }
                        
                        delay: rootItem.ListItem.indexInSection * 100
                    }
                ]
                
                onCreationCompleted: {
                    showAnim.play();
                }
            }
        }
    ]
    
    function remove(ListItemData) {
        sql.query = "DELETE FROM %1 WHERE uri=?".arg(modeDropDown.selectedValue);
        var params = [ListItemData.uri];
        sql.executePrepared(params, QueryId.DeleteEntry);
        
        mainContainer.reload();
    }
    
    function onDataLoaded(id, data)
    {
        if (id == QueryId.GetAll) {
            adm.clear()
            adm.append(data);
        }
    }
    
    onCreationCompleted: {
        sql.dataLoaded.connect(onDataLoaded);
    }
}