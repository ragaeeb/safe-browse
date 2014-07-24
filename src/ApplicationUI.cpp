#include "precompiled.h"

#include "applicationui.hpp"
#include "CardUtils.h"
#include "InvocationUtils.h"
#include "IOUtils.h"
#include "Logger.h"
#include "QueryId.h"
#include "QueryHelper.h"

namespace safebrowse {

using namespace bb::cascades;
using namespace bb::system;
using namespace canadainc;

ApplicationUI::ApplicationUI(bb::cascades::Application *app) :
        QObject(app), m_account(&m_persistance), m_sceneCover("Cover.qml"),
        m_helper(&m_persistance), m_root(NULL)
{
    switch ( m_invokeManager.startupMode() )
    {
        case ApplicationStartupMode::LaunchApplication:
            //LogMonitor::create(UI_KEY, UI_LOG_FILE, this);
            init("main.qml");
            break;

        case ApplicationStartupMode::InvokeCard:
            //LogMonitor::create(CARD_KEY, CARD_LOG_FILE, this);
            connect( &m_invokeManager, SIGNAL( invoked(bb::system::InvokeRequest const&) ), this, SLOT( invoked(bb::system::InvokeRequest const&) ) );
            break;
        case ApplicationStartupMode::InvokeApplication:
            //LogMonitor::create(UI_KEY, UI_LOG_FILE, this);
            connect( &m_invokeManager, SIGNAL( invoked(bb::system::InvokeRequest const&) ), this, SLOT( invoked(bb::system::InvokeRequest const&) ) );
            break;

        default:
            break;
    }
}


void ApplicationUI::init(QString const& qmlDoc)
{
    qmlRegisterUncreatableType<QueryId>("com.canadainc.data", 1, 0, "QueryId", "Can't instantiate");

    QMap<QString, QObject*> context;
    context.insert("security", &m_account);
    context.insert("helper", &m_helper);
    context.insert("app", this);

    LOGGER("Instantiate" << qmlDoc);
    m_root = CardUtils::initAppropriate(qmlDoc, context, this);
    emit initialize();
}


void ApplicationUI::lazyInit()
{
    INIT_SETTING("mode", "passive");
    INIT_SETTING("home", "http://canadainc.org");

    m_helper.initDatabase();

    QString target = m_request.target();

    if ( !target.isNull() ) {
        m_root->setProperty( "target", m_request.uri() );
    } else {
        m_root->setProperty( "target", m_persistance.getValueFor("home") );
    }
}


void ApplicationUI::invoked(bb::system::InvokeRequest const& request)
{
    QString target = request.target();

    LOGGER( request.action() << target << request.mimeType() << request.metadata() << request.uri().toString() << QString( request.data() ) );

    QMap<QString,QString> targetToQML;

    QString qml = targetToQML.value(target);

    if ( qml.isNull() ) {
        qml = "BrowserPane.qml";
    }

    init(qml);

    m_request = request;
}


void ApplicationUI::invokeAdobeReader(QUrl const& uri)
{
    LOGGER(uri);

    bb::system::InvokeRequest request;
    request.setTarget("com.rim.bb.app.adobeReader");
    request.setAction("bb.action.OPEN");
    request.setMimeType("application/pdf");
    request.setUri(uri);

    m_invokeManager.invoke(request);
}


void ApplicationUI::invokeSettingsApp() {
    InvocationUtils::launchSettingsApp("childprotection");
}


void ApplicationUI::create(Application* app) {
	new ApplicationUI(app);
}

ApplicationUI::~ApplicationUI()
{
}

} // salat
