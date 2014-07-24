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

	DatabaseHelper m_sql;
	Persistance* m_persist;

signals:
    void dataReady(int id, QVariant const& data);

private slots:
    void dataLoaded(int id, QVariant const& data);
    void settingChanged(QString const& key);

public:
	QueryHelper(Persistance* persist);
	virtual ~QueryHelper();

    bool initDatabase();
    Q_INVOKABLE void analyze(QString const& domain);
    Q_INVOKABLE void logBlocked(QString const& uri);
    static bool databaseReady();
};

} /* namespace quran */
#endif /* QUERYHELPER_H_ */
