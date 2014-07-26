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
}


void QueryHelper::settingChanged(QString const& key)
{
    if (key == "mode") {
        m_mode = m_persist->getValueFor("mode").toString();
        emit modeChanged();
    }
}


void QueryHelper::analyze(QObject* caller, QUrl const& domain)
{
    LOGGER(domain);

    QStringList tokens = domain.host().split(".");
    LOGGER(tokens);
    int n = tokens.size();

    if (n > 1)
    {
        m_sql.executeQuery(caller, "INSERT INTO logs (action,comment) VALUES ('requested',?)", QueryId::LogRequest, QVariantList() << domain.toString() );

        tokens.takeFirst(); // remove www
        QString host = tokens.join(".");
        m_sql.executeQuery(caller, QString("SELECT uri FROM %1 WHERE uri=? LIMIT 1").arg(m_mode), QueryId::LookupDomain, QVariantList() << host );
    }
}


void QueryHelper::clearAllLogs(QObject* caller)
{
    LOGGER("clearAllLogs");
    m_sql.executeQuery(caller, "DELETE from logs", QueryId::ClearLogs);
}


void QueryHelper::fetchAllLogs(QObject* caller, QString const& filterAction)
{
    LOGGER(filterAction);

    QString query = filterAction.isEmpty() ? "SELECT * from logs ORDER BY timestamp DESC" : QString("SELECT * from logs WHERE action='%1' ORDER BY timestamp DESC").arg(filterAction);
    m_sql.executeQuery(caller, query, QueryId::GetLogs);
}


void QueryHelper::logBlocked(QObject* caller, QString const& uri)
{
    LOGGER(uri);
    m_sql.executeQuery(caller, QString("INSERT INTO logs (action,comment) VALUES ('blocked',?)"), QueryId::LogBlocked, QVariantList() << uri);
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
        qsl << "CREATE TABLE controlled (uri TEXT PRIMARY KEY)";
        qsl << "CREATE TABLE passive (uri TEXT PRIMARY KEY)";
        qsl << "CREATE TABLE logs (id INTEGER PRIMARY KEY AUTOINCREMENT, action TEXT NOT NULL, comment DEFAULT NULL, timestamp DATETIME DEFAULT CURRENT_TIMESTAMP)";

        m_sql.initSetup(NULL, qsl, QueryId::Setup);

        return false;
    }

    settingChanged("mode");

    return true;
}


QString QueryHelper::mode() const {
    return m_mode;
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
