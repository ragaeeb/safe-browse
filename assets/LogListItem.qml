import bb.cascades 1.0

StandardListItem
{
    id: sli
    description: ListItemData.comment
    status: ListItem.view.localization.renderStandardTime(ListItemData.timestamp);
    
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
            
            delay: sli.ListItem.indexInSection * 100
        }
    ]
    
    onCreationCompleted: {
        showAnim.play();
    }
}