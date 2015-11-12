import bb.cascades 1.0
import com.canadainc.data 1.0

BrowserPage
{
    id: safeRunner
    
    function onDataLoaded(id, data)
    {
        if (id == QueryId.InsertEntry) {
            persist.showToast( qsTr("%1 added.").arg( webView.url.toString() ), "images/menu/ic_add.png" );
        }
    }
    
    webView.onUrlChanged: {
        helper.safeRunSite(safeRunner, url);
    }
}