#ifndef THREADUTILS_H_
#define THREADUTILS_H_

#include <QString>

namespace canadainc {
    class Report;
}

namespace safebrowse {

struct BackupStruct
{
    QObject* caller;
    QString callback;
    QString destination;

    BackupStruct(QObject* c=NULL, QString const& cb=QString(), QString const& dest=QString()) : caller(c), callback(cb), destination(dest) {}
};

struct ThreadUtils
{
    static BackupStruct compressDatabase(BackupStruct bs);
    static BackupStruct performRestore(BackupStruct bs);
    static void compressFiles(canadainc::Report& r, QString const& zipPath, const char* password);
};

} /* namespace quran */

#endif /* THREADUTILS_H_ */
