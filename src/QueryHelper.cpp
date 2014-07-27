#include "precompiled.h"

#include "QueryHelper.h"
#include "Logger.h"
#include "Persistance.h"
#include "QueryId.h"

namespace {

QString extractHost(QUrl const& domain)
{
    QStringList tokens = domain.host().toLower().split(".");
    int n = tokens.size();

    if (n > 1)
    {
        if (tokens.first() == "www") {
            tokens.takeFirst(); // remove www
        }

        return tokens.join(".");
    } else {
        return "";
    }
}

}

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

    QString host = extractHost(domain);

    if ( !host.isEmpty() )
    {
        m_sql.executeQuery(caller, "INSERT INTO logs (action,comment) VALUES ('requested',?)", QueryId::LogRequest, QVariantList() << domain.toString() );
        m_sql.executeQuery(caller, QString("SELECT uri FROM %1 WHERE uri=? LIMIT 1").arg(m_mode), QueryId::LookupDomain, QVariantList() << host );
    }
}


void QueryHelper::clearBlockedKeywords(QObject* caller)
{
    LOGGER("clearAllKeywords");
    m_sql.executeQuery(caller, "DELETE from keywords", QueryId::ClearKeywords);
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


void QueryHelper::fetchAllBlockedKeywords(QObject* caller)
{
    LOGGER("fetchAllBlockedKeywords");
    m_sql.executeQuery(caller, "SELECT term FROM keywords ORDER BY term", QueryId::GetKeywords);
}


QStringList QueryHelper::blockKeywords(QObject* caller, QVariantList const& keywords)
{
    LOGGER(keywords);

    QStringList all;
    QStringList keywordsList;
    all << QString("INSERT OR IGNORE INTO keywords (term) SELECT ? AS 'term'");
    QString addition = QString("UNION SELECT ?");

    for (int i = keywords.size()-1; i >= 0; i--)
    {
        all << addition;
        keywordsList << keywords[i].toString();
    }

    all.removeLast();

    m_sql.executeQuery(caller, all.join(" "), QueryId::InsertKeyword, keywords);

    return keywordsList;
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


void QueryHelper::blockSite(QObject* caller, QString const& mode, QString uri)
{
    LOGGER(mode << uri);

    uri = extractHost( QUrl::fromUserInput(uri) );

    if ( !uri.isEmpty() ) {
        m_sql.executeQuery(caller, QString("INSERT INTO %1 (uri) VALUES (?)").arg(mode), QueryId::InsertEntry, QVariantList() << uri);
    }
}


void QueryHelper::fetchAllBlocked(QObject* caller, QString const& mode)
{
    LOGGER(mode);
    m_sql.executeQuery( caller, QString("SELECT uri FROM %1").arg(mode), QueryId::GetAll );
}


void QueryHelper::unblockSite(QObject* caller, QString const& mode, QVariantList const& uris)
{
    LOGGER(mode << uris);

    QStringList placeHolders;
    QVariantList values;

    foreach (QVariant const& uri, uris) {
        placeHolders << "?";
        values << uri.toMap().value("uri").toString();
    }

    m_sql.executeQuery(caller, QString("DELETE FROM %1 WHERE uri IN (%2)").arg(mode).arg( placeHolders.join(",") ), QueryId::DeleteEntry, values);
}


bool QueryHelper::initDatabase()
{
    if ( !databaseReady() )
    {
        QStringList qsl;
        qsl << "CREATE TABLE controlled (uri TEXT PRIMARY KEY)";
        qsl << "CREATE TABLE passive (uri TEXT PRIMARY KEY)";
        qsl << "CREATE TABLE passive (uri TEXT PRIMARY KEY)";
        qsl << "CREATE TABLE logs (id INTEGER PRIMARY KEY AUTOINCREMENT, action TEXT NOT NULL, comment DEFAULT NULL, timestamp DATETIME DEFAULT CURRENT_TIMESTAMP)";
        qsl << "CREATE TABLE IF NOT EXISTS keywords ( term TEXT PRIMARY KEY, CHECK(term <> '') )";

        m_sql.initSetup(NULL, qsl, QueryId::Setup);

        if ( !m_persist->contains("keywordsCreated") ) {
            m_persist->saveValueFor("keywordsCreated",true,false);
        }

        return false;
    } else if ( !m_persist->contains("keywordsCreated") ) {
        m_sql.executeQuery(NULL, "CREATE TABLE IF NOT EXISTS keywords ( term TEXT PRIMARY KEY, CHECK(term <> '') )", QueryId::Setup);
        m_persist->saveValueFor("keywordsCreated",true,false);
    }

    settingChanged("mode");

    return true;
}


QStringList QueryHelper::unblockKeywords(QObject* caller, QVariantList const& keywords)
{
    LOGGER("unblockKeywords" << keywords);

    QStringList keywordsList;
    QVariantList keywordsVariants;
    QStringList placeHolders;

    for (int i = keywords.size()-1; i >= 0; i--)
    {
        QString current = keywords[i].toMap().value("term").toString();
        keywordsVariants << current;
        keywordsList << current;
        placeHolders << "?";
    }

    m_sql.executeQuery( caller, QString("DELETE FROM keywords WHERE term IN (%1)").arg( placeHolders.join(",") ), QueryId::DeleteKeyword, keywordsVariants);

    return keywordsList;
}


void QueryHelper::safeRunSite(QObject* caller, QUrl const& domain)
{
    LOGGER(domain);

    QString host = extractHost(domain);

    if ( !host.isEmpty() ) {
        blockSite(caller, m_mode, host);
    }
}


void QueryHelper::analyzeKeywords(QObject* caller, QString const& title)
{
    LOGGER(title);

    if (m_mode == "passive")
    {
        QStringList tokens = title.trimmed().toLower().split(" ");
        QVariantList values;
        QStringList placeHolders;
        static QRegExp regex("[a-z]+");

        foreach (QString const& token, tokens)
        {
            if ( token.length() > 2 && regex.exactMatch(token) )
            {
                values << token;
                placeHolders << "?";
            }
        }

        if ( !values.isEmpty() )
        {
            QString keywordQuery = QString("SELECT term FROM keywords WHERE term IN (%1)").arg( placeHolders.join(",") );
            m_sql.executeQuery(caller, keywordQuery, QueryId::LookupKeywords, values);
        }
    }
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
