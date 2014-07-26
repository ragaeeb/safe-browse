#include "precompiled.h"

#include "SafeBrowseCollector.h"
#include "JlCompress.h"
#include "QueryHelper.h"

namespace safebrowse {

using namespace canadainc;

SafeBrowseCollector::SafeBrowseCollector()
{
}


QString SafeBrowseCollector::appName() const {
    return "safe_browse";
}


QByteArray SafeBrowseCollector::compressFiles()
{
    AppLogFetcher::dumpDeviceInfo();

    QStringList files;
    files << DEFAULT_LOGS;
    files << CARD_LOG_FILE;
    files << DATABASE_PATH;

    for (int i = files.size()-1; i >= 0; i--)
    {
        QFile current(files[i]);

        if ( !current.exists() ) {
            files.removeAt(i);
        }
    }

    JlCompress::compressFiles(ZIP_FILE_PATH, files);

    QFile f(ZIP_FILE_PATH);
    f.open(QIODevice::ReadOnly);

    QByteArray qba = f.readAll();
    f.close();

    QFile::remove(CARD_LOG_FILE);
    QFile::remove(UI_LOG_FILE);

    return qba;
}


SafeBrowseCollector::~SafeBrowseCollector()
{
}

} /* namespace autoblock */
