#include "precompiled.h"

#include "QueryHelper.h"
#include "Logger.h"
#include "Persistance.h"
#include "QueryId.h"

namespace safebrowse {

using namespace canadainc;

QueryHelper::QueryHelper(Persistance* persist) :
        m_sql(DATABASE_PATH), m_persist(persist)
{
    connect( persist, SIGNAL( settingChanged(QString const&) ), this, SLOT( settingChanged(QString const&) ), Qt::QueuedConnection );
    connect( &m_sql, SIGNAL( dataLoaded(int, QVariant const&) ), this, SLOT( dataLoaded(int, QVariant const&) ), Qt::QueuedConnection );
}


void QueryHelper::dataLoaded(int id, QVariant const& data)
{

}


void QueryHelper::settingChanged(QString const& key)
{
    Q_UNUSED(key);
}


void QueryHelper::analyze(QString const& domain)
{
    /*
    QString mode = m_persist->getValueFor("mode").toString();
    m_sql.setQuery( QString("SELECT * FROM %1 WHERE uri=? LIMIT 1").arg(mode) );
    QVariantList params = QVariantList() << domain;
    m_sql.executePrepared(params, QueryId::LookupDomain);

    m_sql.setQuery( QString("INSERT INTO logs (action,comment) VALUES ('%1',?)").arg("requested") );
    m_sql.executePrepared(params, QueryId::LogRequest); */
}


void QueryHelper::logBlocked(QString const& uri)
{
    /*
    m_sql.setQuery( QString("INSERT INTO logs (action,comment) VALUES ('%1',?)").arg("blocked") );
    m_sql.executePrepared( QVariantList() << uri, QueryId::LogBlocked ); */
}


void QueryHelper::logFailedLogin(QObject* caller, QString const& inputPassword)
{
    LOGGER(inputPassword);
    m_sql.executeQuery(caller, "INSERT INTO logs (action,comment) VALUES ('failed_login',?)", QueryId::LogFailedLogin, QVariantList() << inputPassword);
}


void QueryHelper::blockSite(QObject* caller, QString const& mode, QString const& uri)
{
    LOGGER(mode << uri);
    m_sql.executeQuery(caller, QString("INSERT INTO %1 (uri) VALUES (?)").arg(mode), QueryId::InsertEntry, QVariantList() << uri);
}


void QueryHelper::fetchAllBlocked(QObject* caller, QString const& mode)
{
    LOGGER(mode);
    m_sql.executeQuery( caller, QString("SELECT uri FROM %1").arg(mode), QueryId::GetAll );
}


void QueryHelper::unblockSite(QObject* caller, QString const& mode, QString const& uri)
{
    LOGGER(mode << uri);
    m_sql.executeQuery(caller, QString("DELETE FROM %1 WHERE uri=?").arg(mode), QueryId::DeleteEntry, QVariantList() << uri);
}


bool QueryHelper::initDatabase()
{
    if ( !databaseReady() )
    {
        QStringList qsl;
        qsl << "CREATE TABLE passive (uri TEXT PRIMARY KEY)";
        qsl << "CREATE TABLE controlled (uri TEXT PRIMARY KEY)";
        qsl << "CREATE TABLE logs (id INTEGER PRIMARY KEY AUTOINCREMENT, action TEXT NOT NULL, comment DEFAULT NULL, timestamp DATETIME DEFAULT CURRENT_TIMESTAMP)";

        m_sql.initSetup(NULL, qsl, QueryId::Setup);

        return false;
    }

    return true;
}


bool QueryHelper::databaseReady()
{
    QFile dbPath(DATABASE_PATH);
    return dbPath.exists() && dbPath.size() > 0;
}


QueryHelper::~QueryHelper()
{
}

} /* namespace oct10 */
