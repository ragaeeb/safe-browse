#ifndef QUERYHELPER_H_
#define QUERYHELPER_H_

#include "DatabaseHelper.h"

#define DATABASE_PATH QString("%1/database.db").arg( QDir::homePath() )

namespace canadainc {
	class Persistance;
}

namespace safebrowse {

using namespace canadainc;

class QueryHelper : public QObject
{
	Q_OBJECT
	Q_PROPERTY(QString mode READ mode FINAL)
	Q_PROPERTY(int threshold READ threshold FINAL)

	DatabaseHelper m_sql;
	Persistance* m_persist;
	QString m_mode;
	int m_threshold;

signals:
    void modeChanged();

private slots:
    void settingChanged(QString const& key);

public:
	QueryHelper(Persistance* persist);
	virtual ~QueryHelper();

    bool initDatabase();
    QString mode() const;
    int threshold() const;
    Q_INVOKABLE void analyze(QObject* caller, QUrl const& domain);
    Q_INVOKABLE void analyzeKeywords(QObject* caller, QString const& title);
    Q_INVOKABLE QStringList blockKeywords(QObject* caller, QVariantList const& keywords);
    Q_INVOKABLE void blockSite(QObject* caller, QString const& mode, QString uri);
    Q_INVOKABLE void clearAllLogs(QObject* caller);
    Q_INVOKABLE void clearBlockedKeywords(QObject* caller);
    Q_INVOKABLE void clearCache(QObject* caller);
    Q_INVOKABLE void fetchAllBlocked(QObject* caller, QString const& mode);
    Q_INVOKABLE void fetchAllBlockedKeywords(QObject* caller);
    Q_INVOKABLE void fetchAllLogs(QObject* caller, QString const& filterAction=QString());
    Q_INVOKABLE void logBlocked(QObject* caller, QString const& uri);
    Q_INVOKABLE void logFailedLogin(QObject* caller, QString const& inputPassword);
    Q_INVOKABLE void safeRunSite(QObject* caller, QUrl const& domain);
    Q_INVOKABLE QStringList unblockKeywords(QObject* caller, QVariantList const& keywords);
    Q_INVOKABLE void unblockSite(QObject* caller, QString const& mode, QVariantList const& uris);
    static bool databaseReady();
};

} /* namespace quran */
#endif /* QUERYHELPER_H_ */
