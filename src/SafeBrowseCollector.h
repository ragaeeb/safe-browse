#ifndef SAFEBROWSECOLLECTOR_H_
#define SAFEBROWSECOLLECTOR_H_

#include "AppLogFetcher.h"

#define CARD_LOG_FILE QString("%1/logs/card.log").arg( QDir::currentPath() )

namespace safebrowse {

using namespace canadainc;

class SafeBrowseCollector : public LogCollector
{
public:
    SafeBrowseCollector();
    QString appName() const;
    QByteArray compressFiles();
    ~SafeBrowseCollector();
};

} /* namespace autoblock */

#endif /* SAFEBROWSECOLLECTOR_H_ */
