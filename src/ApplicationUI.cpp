#include "precompiled.h"

#include "applicationui.hpp"
#include "Logger.h"
#include "QueryId.h"

namespace safebrowse {

using namespace bb::cascades;
using namespace bb::system;
using namespace canadainc;

ApplicationUI::ApplicationUI(bb::cascades::Application *app) : QObject(app), m_account(&m_persistance), m_sceneCover("Cover.qml")
{
	INIT_SETTING("mode", "passive");
	INIT_SETTING("home", "http://abdurrahman.org");

	QString database = QString("%1/database.db").arg( QDir::homePath() );
	m_sql.setSource(database);

	if ( !QFile(database).exists() ) {
		QStringList qsl;
		qsl << "CREATE TABLE passive (uri TEXT PRIMARY KEY)";
		qsl << "CREATE TABLE controlled (uri TEXT PRIMARY KEY)";
		qsl << "CREATE TABLE logs (id INTEGER PRIMARY KEY AUTOINCREMENT, action TEXT NOT NULL, comment DEFAULT NULL, timestamp DATETIME DEFAULT CURRENT_TIMESTAMP)";
		m_sql.initSetup(qsl, 99);
	}

	qmlRegisterUncreatableType<QueryId>("com.canadainc.data", 1, 0, "QueryId", "Can't instantiate");

	QmlDocument* qml = QmlDocument::create("asset:///main.qml").parent(this);
    qml->setContextProperty("persist", &m_persistance);
    qml->setContextProperty("security", &m_account);
    qml->setContextProperty("sql", &m_sql);
    qml->setContextProperty("localizer", &m_locale);
    qml->setContextProperty("app", this);

    AbstractPane* root = qml->createRootObject<AbstractPane>();
    app->setScene(root);

	switch ( m_invokeManager.startupMode() )
	{
		case ApplicationStartupMode::InvokeApplication:
		case ApplicationStartupMode::InvokeCard:
			LOGGER("INVOKED!!");
			break;

		default:
			QUrl home = QUrl( m_persistance.getValueFor("home").toString() );
			LOGGER("Setting homepage" << home);
			root->setProperty("target", home);
			break;
	}

	connect( &m_invokeManager, SIGNAL( invoked(bb::system::InvokeRequest const&) ), this, SLOT( invoked(bb::system::InvokeRequest const&) ) );
}


void ApplicationUI::invoked(bb::system::InvokeRequest const& request)
{
	QUrl uri = request.uri();
	LOGGER("========= INVOKED WITH" << uri );

	Application::instance()->scene()->setProperty("target", uri);
}


void ApplicationUI::analyze(QString const& domain)
{
    QString mode = m_persistance.getValueFor("mode").toString();
    m_sql.setQuery( QString("SELECT * FROM %1 WHERE uri=? LIMIT 1").arg(mode) );
    QVariantList params = QVariantList() << domain;
    m_sql.executePrepared(params, QueryId::LookupDomain);

    m_sql.setQuery( QString("INSERT INTO logs (action,comment) VALUES ('%1',?)").arg("requested") );
    m_sql.executePrepared(params, QueryId::LogRequest);
}


void ApplicationUI::logBlocked(QString const& uri)
{
    m_sql.setQuery( QString("INSERT INTO logs (action,comment) VALUES ('%1',?)").arg("blocked") );
    m_sql.executePrepared( QVariantList() << uri, QueryId::LogBlocked );
}


void ApplicationUI::invokeSettingsApp()
{
	bb::system::InvokeManager invokeManager;

	bb::system::InvokeRequest request;
	request.setTarget("sys.settings.target");
	request.setAction("bb.action.OPEN");
	request.setMimeType("settings/view");
	request.setUri( QUrl("settings://childprotection") );

	invokeManager.invoke(request);
}


void ApplicationUI::create(Application* app) {
	new ApplicationUI(app);
}

ApplicationUI::~ApplicationUI()
{
}

} // salat
