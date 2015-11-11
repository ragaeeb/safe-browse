#include "precompiled.h"

#include "ThreadUtils.h"
#include "AppLogFetcher.h"
#include "CommonConstants.h"
#include "Logger.h"
#include "JlCompress.h"
#include "Report.h"

namespace safebrowse {

using namespace canadainc;

void ThreadUtils::compressFiles(Report& r, QString const& zipPath, const char* password)
{
    if (r.type == ReportType::BugReportAuto || r.type == ReportType::BugReportManual) {
        r.attachments << DATABASE_PATH;
    }

    JlCompress::compressFiles(zipPath, r.attachments, password);
}

} /* namespace autoblock */
