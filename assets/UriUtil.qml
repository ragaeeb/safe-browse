import bb.cascades 1.0

QtObject
{
    function removeProtocol(request)
    {
        if ( request.indexOf("http://") == 0 ) {
            request = request.substr("http://".length);
        }
        
        if ( request.indexOf("www.") == 0 ) {
            request = request.substr("www.".length);
        }
        
        return request;
    }
}