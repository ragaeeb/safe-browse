#include "precompiled.h"

#include "applicationui.hpp"
#include "Logger.h"

namespace safebrowse {

using namespace bb::cascades;
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

	QmlDocument* qml = QmlDocument::create("asset:///main.qml").parent(this);
    qml->setContextProperty("persist", &m_persistance);
    qml->setContextProperty("security", &m_account);
    qml->setContextProperty("sql", &m_sql);
    qml->setContextProperty("localizer", &m_locale);
    qml->setContextProperty("app", this);

    AbstractPane* root = qml->createRootObject<AbstractPane>();
    app->setScene(root);
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
